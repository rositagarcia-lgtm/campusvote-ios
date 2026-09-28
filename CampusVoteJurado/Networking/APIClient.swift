import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private struct Envelope<Payload: Decodable>: Decodable {
        let success: Bool
        let message: String?
        let data: Payload?
    }

    private struct VoidPayload: Decodable {}

    private init() {}

    var hasSavedSession: Bool {
        KeychainStore.readToken(for: .access) != nil
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

    func send<T: Decodable>(_ event: Endpoint, as type: T.Type) async throws -> T {
        let data = try await perform(event)
        let envelope = try decodeEnvelope(Envelope<T>.self, from: data)
        guard let payload = envelope.data else {
            throw APIError.decoding("La respuesta no contiene el campo data esperado.")
        }
        return payload
    }

    func send(_ event: Endpoint) async throws {
        let data = try await perform(event)
        _ = try? decodeEnvelope(Envelope<VoidPayload>.self, from: data)
    }

    private func perform(_ event: Endpoint) async throws -> Data {
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

        if httpResponse.statusCode == 401, event.usesStoredToken {
            clearTokens()
            throw APIError.sessionExpired
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
