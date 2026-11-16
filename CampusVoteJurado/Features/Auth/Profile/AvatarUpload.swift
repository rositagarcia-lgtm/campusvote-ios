import Foundation
import UIKit

/// Sube la foto hasta que el servidor la confirma. El usuario no ve los intentos.
@MainActor
enum AvatarUpload {
    private static var task: Task<Void, Never>?
    private static var generation = 0

    static func submit(jpeg: Data) {
        generation += 1
        let ticket = generation
        task?.cancel()
        task = Task {
            var wait: UInt64 = 2_000_000_000
            while !Task.isCancelled, ticket == generation {
                if await send(jpeg) { return }
                try? await Task.sleep(nanoseconds: wait)
                wait = min(wait * 2, 30_000_000_000)
            }
        }
    }

    static func cancel() {
        generation += 1
        task?.cancel()
        task = nil
    }

    private static func send(_ jpeg: Data) async -> Bool {
        do {
            _ = try await APIClient.shared.uploadAvatar(jpeg: jpeg)
            let profile = try await APIClient.shared.send(
                Endpoint(path: "users/me", method: "GET"),
                as: JuryProfile.self
            )
            guard let url = profile.avatarURL else { return false }
            PortraitStore.shared.remoteURL = url
            return true
        } catch {
            return false
        }
    }
}
