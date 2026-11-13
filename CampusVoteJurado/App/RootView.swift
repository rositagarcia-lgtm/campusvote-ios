import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @State private var minimumSplashDone = false

    private let splashDuration: Duration = .seconds(2.2)
    // La tarea se cancela al salir de la sesión o al dejar de estar en primer plano.
    private let brandRefreshInterval: Duration = .seconds(5)

    private var brandPollingID: String? {
        guard scenePhase == .active, case .signedIn(let user) = session.phase,
              let organizationId = user.organizationId, !organizationId.isEmpty else { return nil }
        return "\(user.id)/\(organizationId)"
    }

    var body: some View {
        Group {
            if session.phase == .checking || !minimumSplashDone {
                SplashView()
                    .task {
                        try? await Task.sleep(for: splashDuration)
                        minimumSplashDone = true
                    }
            } else {
                switch session.phase {

                case .checking:
                    SplashView()

                case .signedOut:
                    LoginView()

                case .needsCode:
                    TotpView()

                case .mustChangePassword:
                    ChangePasswordView()

                case .signedIn(let user):
                    SignedInExperience(user: user)
                        .id(user.id)
                }
            }
        }
        .task {
            await session.restore()
        }
        .task(id: brandPollingID) {
            guard brandPollingID != nil else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: brandRefreshInterval)
                } catch {
                    return
                }
                guard !Task.isCancelled, scenePhase == .active else { return }
                await session.refreshBrand()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await session.refreshBrand() }
        }
    }
}
