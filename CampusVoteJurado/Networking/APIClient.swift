import Foundation

extension Notification.Name {
    /// La sesión del jurado ya no es válida. SessionStore vuelve al login.
    static let campusVoteSessionExpired = Notification.Name("campusvote.session.expired")
}

struct PageInfo: Decodable, Hashable {
    let page: Int
    let limit: Int
    let total: Int

    var totalPages: Int {
        guard limit > 0 else { return 0 }
        return Int(ceil(Double(total) / Double(limit)))
    }

    init(page: Int, limit: Int, total: Int) {
        self.page = page
        self.limit = limit
        self.total = total
    }
}

struct PageResult<Item> {
    let items: [Item]
    let pagination: PageInfo
}

/// Cliente HTTP que habla con el backend de CampusVote.
///
/// Cada respuesta viaja en un envelope `{ success, message, data }`.
/// `send(_:as:)` desempaqueta `data`. Un 401 con el token de sesión cierra la sesión.
final class APIClient: Sendable {
    static let shared = APIClient()
    private let refreshCoordinator = RefreshCoordinator()

    // MARK: - Envelope

    private struct Envelope<Payload: Decodable>: Decodable {
        let success: Bool
        let message: String?
        let data: Payload?
    }

    private struct VoidPayload: Decodable {}

    private struct PagedEnvelope<Payload: Decodable>: Decodable {
        let success: Bool
        let message: String?
        let data: [Payload]?
        let pagination: PageInfo?
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
        guard let payload = envelope.data else {
            throw APIError.decoding("La respuesta no contiene el campo data esperado.")
        }
        return payload
    }

    func sendPage<T: Decodable>(_ event: Endpoint, as type: T.Type) async throws -> PageResult<T> {
        let data = try await perform(event)
        let envelope = try decodeEnvelope(PagedEnvelope<T>.self, from: data)
        let items = envelope.data ?? []
        let pagination = envelope.pagination
            ?? PageInfo(page: 1, limit: max(items.count, 1), total: items.count)
        return PageResult(items: items, pagination: pagination)
    }

    func send(_ event: Endpoint) async throws {
        let data = try await perform(event)
        _ = try? decodeEnvelope(Envelope<VoidPayload>.self, from: data)
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
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let urlResponse = response as? HTTPURLResponse else {
                throw APIError.decoding("El servidor no devolvió una respuesta HTTP válida.")
            }
            data = responseData
            httpResponse = urlResponse
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network
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
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.network
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
        return .server(status: status, code: "HTTP_\(status)", message: "El servidor respondió con el estado \(status).")
    }
}

private actor RefreshCoordinator {
    private var refreshTask: Task<AuthResult, Error>?

    func refresh(
        operation: @escaping @Sendable (String) async throws -> AuthResult
    ) async throws -> AuthResult {
        if let refreshTask {
            return try await refreshTask.value
        }
        guard let refreshToken = KeychainStore.readToken(for: .refresh) else {
            throw APIError.sessionExpired
        }

        let task = Task { try await operation(refreshToken) }
        refreshTask = task
        do {
            let result = try await task.value
            refreshTask = nil
            return result
        } catch {
            refreshTask = nil
            throw error
        }
    }
}
