import Foundation

/// Cliente HTTP que habla con el backend de CampusVote.
///
/// Cada respuesta viaja en un envelope `{ success, message, data }`.
/// `send(_:as:)` desempaqueta `data`. Un 401 con el token de sesión cierra la sesión.
final class APIClient: Sendable {
    static let shared = APIClient()
    private let refreshCoordinator = RefreshCoordinator()
    private let session = APITransport.session

    // MARK: - Envelope

    private struct Envelope<Payload: Decodable>: Decodable {
        let success: Bool
        let message: String?
        let data: Payload?
    }

    private struct VoidPayload: Decodable {}

    private struct PagedEnvelope<Payload: Decodable>: Decodable {
        struct Meta: Decodable {
            let pagination: PageInfo?
        }

        let success: Bool
        let message: String?
        let data: [Payload]?
        let pagination: PageInfo?
        let meta: Meta?
    }

    private init() {}

    // MARK: - Sesión persistida

    var hasSavedSession: Bool {
        KeychainStore.readToken(for: .access) != nil
    }

    var savedRefreshToken: String? {
        KeychainStore.readToken(for: .refresh)
    }

    func saveTokens(access: String, refresh: String?) throws {
        guard KeychainStore.save(access, for: .access) else {
            clearTokens()
            throw APIError.secureStorage
        }
        guard let refresh else {
            KeychainStore.deleteToken(for: .refresh)
            return
        }
        guard KeychainStore.save(refresh, for: .refresh) else {
            clearTokens()
            throw APIError.secureStorage
        }
    }

    func clearTokens() {
        KeychainStore.deleteToken(for: .access)
        KeychainStore.deleteToken(for: .refresh)
    }

    // MARK: - Peticiones

    func send<T: Decodable>(_ event: Endpoint, as type: T.Type) async throws -> T {
        let data = try await perform(event)
        let envelope = try decodeEnvelope(Envelope<T>.self, from: data)
        guard envelope.success else {
            throw APIError.decoding(envelope.message ?? "La operación no fue completada por el servidor.")
        }
        guard let payload = envelope.data else {
            throw APIError.decoding("La respuesta no contiene el campo data esperado.")
        }
        return payload
    }

    func sendPage<T: Decodable>(_ event: Endpoint, as type: T.Type) async throws -> PageResult<T> {
        let data = try await perform(event)
        let envelope = try decodeEnvelope(PagedEnvelope<T>.self, from: data)
        guard envelope.success else {
            throw APIError.decoding(envelope.message ?? "La operación no fue completada por el servidor.")
        }
        let items = envelope.data ?? []
        let pagination = envelope.pagination ?? envelope.meta?.pagination
            ?? PageInfo(page: 1, limit: max(items.count, 1), total: items.count)
        return PageResult(items: items, pagination: pagination)
    }

    func send(_ event: Endpoint) async throws {
        let data = try await perform(event)
        guard !data.isEmpty else { return }
        let envelope = try decodeEnvelope(Envelope<VoidPayload>.self, from: data)
        guard envelope.success else {
            throw APIError.decoding(envelope.message ?? "La operación no fue completada por el servidor.")
        }
    }

    // MARK: - Ejecución

    private func perform(_ event: Endpoint, canRefresh: Bool = true) async throws -> Data {
        let request: URLRequest
        do {
            request = try makeRequest(for: event)
        } catch {
            throw APIError.network
        }

        let data: Data
        let httpResponse: HTTPURLResponse
        do {
            let (responseData, response) = try await session.data(for: request)
            guard let urlResponse = response as? HTTPURLResponse else {
                throw APIError.decoding("El servidor no devolvió una respuesta HTTP válida.")
            }
            data = responseData
            httpResponse = urlResponse
        } catch let error as APIError {
            throw error
        } catch {
            try APITransport.throwNormalized(error)
        }

        if httpResponse.statusCode == 401,
           event.usesStoredToken,
           event.retriesWithRefresh,
           canRefresh,
           savedRefreshToken != nil {
            do {
                _ = try await refreshCoordinator.refresh { [self] refreshToken in
                    try await refreshSession(refreshToken: refreshToken)
                }
                return try await perform(event, canRefresh: false)
            } catch let error as APIError {
                // Solo cerramos la sesión si el servidor rechazó los tokens.
                // Un corte de red durante el refresh no debe expulsar al jurado.
                if error.isSessionRejection {
                    expireSession()
                }
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw APIError.network
            }
        }

        if httpResponse.statusCode == 401, event.usesStoredToken {
            expireSession()
            throw APIError.sessionExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw Self.mapError(status: httpResponse.statusCode, data: data)
        }

        return data
    }

    private func refreshSession(refreshToken: String) async throws -> AuthResult {
        let request = try makeRequest(for: .refresh(refreshToken: refreshToken))
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            try APITransport.throwNormalized(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.network
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw Self.mapError(status: httpResponse.statusCode, data: data)
        }

        let envelope = try decodeEnvelope(Envelope<AuthResult>.self, from: data)
        guard let result = envelope.data,
              let accessToken = result.token,
              let newRefreshToken = result.refreshToken else {
            throw APIError.decoding("La renovación no devolvió los tokens esperados.")
        }
        try saveTokens(access: accessToken, refresh: newRefreshToken)
        return result
    }

    private func expireSession() {
        clearTokens()
        NotificationCenter.default.post(name: .campusVoteSessionExpired, object: nil)
    }

    private func makeRequest(for event: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent(event.path), resolvingAgainstBaseURL: false) else {
            throw APIError.network
        }
        if !event.queryItems.isEmpty {
            components.queryItems = event.queryItems
        }
        guard let url = components.url else {
            throw APIError.network
        }

        var request = URLRequest(url: url)
        request.httpMethod = event.method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(selectedLanguage, forHTTPHeaderField: "Accept-Language")

        if let explicitToken = event.explicitToken {
            request.setValue("Bearer \(explicitToken)", forHTTPHeaderField: "Authorization")
        } else if event.usesStoredToken, let token = KeychainStore.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = event.body {
            request.httpBody = try JSONCoding.makeEncoder().encode(AnyEncodable(body))
        }

        return request
    }

    private var selectedLanguage: String {
        UserDefaults.standard.string(forKey: "campusvote.preferences.language") == "en" ? "en" : "es"
    }

    private func decodeEnvelope<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONCoding.makeDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private static func mapError(status: Int, data: Data) -> APIError {
        if let body = try? JSONCoding.makeDecoder().decode(ServerErrorBody.self, from: data) {
            return .server(status: status, code: body.error.code, message: body.error.message)
        }
        let locale = Locale(identifier: UserDefaults.standard.string(forKey: "campusvote.preferences.language") ?? "es")
        return .server(status: status, code: "HTTP_\(status)", message: L10n.format("El servidor respondió con el estado %d.", locale: locale, status))
    }
}
