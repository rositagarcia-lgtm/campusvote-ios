import Foundation

/// Cliente HTTP que habla con el backend de CampusVote.
///
/// Cada respuesta viaja en un envelope `{ success, message, data, meta }`.
/// `send(_:as:)` desempaqueta automáticamente `data`. Si el access token venció
/// (401) y hay un refresh token guardado, se renueva la sesión y se reintenta
/// la petición original una vez.
final class APIClient: Sendable {
    static let shared = APIClient()

    // MARK: - Envelope

    private struct Envelope<Payload: Decodable>: Decodable {
        let success: Bool
        let message: String?
        let data: Payload?
    }

    private struct VoidPayload: Decodable {}

    private init() {}

    // MARK: - Sesión persistida

    var hasSavedSession: Bool {
        KeychainStore.readToken(for: .access) != nil
    }

    var savedRefreshToken: String? {
        KeychainStore.readToken(for: .refresh)
    }

    func saveTokens(access: String, refresh: String?) {
        KeychainStore.save(access, for: .access)
        if let refresh {
            KeychainStore.save(refresh, for: .refresh)
        } else {
            KeychainStore.deleteToken(for: .refresh)
        }
    }

    func clearTokens() {
        KeychainStore.deleteToken(for: .access)
        KeychainStore.deleteToken(for: .refresh)
    }

    // MARK: - Peticiones

    func send<T: Decodable>(_ event: Endpoint, as type: T.Type) async throws -> T {
        let data = try await perform(event, allowRetry: true)
        let envelope = try decodeEnvelope(Envelope<T>.self, from: data)
        guard let payload = envelope.data else {
            throw APIError.decoding("La respuesta no contiene el campo data esperado.")
        }
        return payload
    }

    func send(_ event: Endpoint) async throws {
        let data = try await perform(event, allowRetry: true)
        _ = try? decodeEnvelope(Envelope<VoidPayload>.self, from: data)
    }

    // MARK: - Ejecución

    private func perform(_ event: Endpoint, allowRetry: Bool) async throws -> Data {
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

        // 401 con stale token: renueva y reintenta una vez.
        if httpResponse.statusCode == 401,
           allowRetry,
           event.usesStoredToken,
           case .some(let refreshToken) = savedRefreshToken {

            do {
                let refreshed = try await refreshSession(refreshToken: refreshToken)
                guard let newAccessToken = refreshed.token else {
                    clearTokens()
                    throw APIError.sessionExpired
                }
                KeychainStore.save(newAccessToken, for: .access)
                if let newRefresh = refreshed.refreshToken {
                    KeychainStore.save(newRefresh, for: .refresh)
                }
            } catch {
                clearTokens()
                throw APIError.sessionExpired
            }

            let retryRequest = try makeRequest(for: event)
            let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
            guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                throw APIError.network
            }
            guard (200...299).contains(retryHTTP.statusCode) else {
                throw Self.mapError(status: retryHTTP.statusCode, data: retryData)
            }
            return retryData
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw Self.mapError(status: httpResponse.statusCode, data: data)
        }

        return data
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
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    private func refreshSession(refreshToken: String) async throws -> AuthResult {
        let request = try makeRequest(for: .refresh(refreshToken: refreshToken))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.network
        }
        guard (200...299).contains(http.statusCode) else {
            throw Self.mapError(status: http.statusCode, data: data)
        }
        guard let result = try decodeEnvelope(Envelope<AuthResult>.self, from: data).data else {
            throw APIError.decoding("La renovación de sesión no devolvió tokens.")
        }
        return result
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
