import Foundation

enum Renewal {
    case refreshed, invalid, unavailable
}

extension APIClient {
    func renewAfterUnauthorized() async -> Renewal {
        let previous = savedRefreshToken ?? ""
        guard !previous.isEmpty else { return .invalid }
        do {
            _ = try await refreshCoordinator.refresh { [self] token in
                try await refreshSession(refreshToken: token)
            }
            return .refreshed
        } catch let error as APIError {
            if error.code == "REFRESH_IN_PROGRESS" {
                let saved = savedRefreshToken ?? ""
                return !saved.isEmpty && saved != previous ? .refreshed : .unavailable
            }
            let rejected = error.isSessionRejection
                || error.code == "UNAUTHORIZED"
                || error.code == "FORBIDDEN"
            return rejected ? .invalid : .unavailable
        } catch {
            return .unavailable
        }
    }

    func refreshSession(refreshToken: String) async throws -> AuthResult {
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
        guard savedRefreshToken == refreshToken else {
            throw APIError.server(
                status: 409,
                code: "REFRESH_IN_PROGRESS",
                message: "La sesión se está renovando"
            )
        }
        try saveTokens(access: accessToken, refresh: newRefreshToken)
        return result
    }
}

actor RefreshCoordinator {
    private var refreshTask: Task<AuthResult, Error>?
    private var tokenInFlight: String?

    func refresh(
        operation: @escaping @Sendable (String) async throws -> AuthResult
    ) async throws -> AuthResult {
        guard let refreshToken = KeychainStore.readToken(for: .refresh) else {
            throw APIError.sessionExpired
        }
        if let refreshTask, tokenInFlight == refreshToken {
            return try await refreshTask.value
        }

        let task = Task { try await operation(refreshToken) }
        tokenInFlight = refreshToken
        refreshTask = task
        do {
            let result = try await task.value
            clearTask(for: refreshToken)
            return result
        } catch {
            clearTask(for: refreshToken)
            throw error
        }
    }

    private func clearTask(for token: String) {
        guard tokenInFlight == token else { return }
        refreshTask = nil
        tokenInFlight = nil
    }
}
