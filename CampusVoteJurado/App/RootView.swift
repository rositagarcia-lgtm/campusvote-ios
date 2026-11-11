import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @State private var minimumSplashDone = false

    private let splashDuration: Duration = .seconds(2.2)
    private let brandRefreshInterval: Duration = .seconds(20)

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
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: brandRefreshInterval)
                guard !Task.isCancelled else { return }
                await session.refreshBrand()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await session.refreshBrand() }
        }
    }
}
