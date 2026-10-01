import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session
    @State private var minimumSplashDone = false

    private let splashDuration: Duration = .seconds(2.2)

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

                case .signedIn:
                    MainTabView()
                }
            }
        }
        .task {
            await session.restore()
        }
    }
}
