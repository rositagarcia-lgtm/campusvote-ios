import Foundation

actor RefreshCoordinator {
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
