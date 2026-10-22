import Foundation

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
