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

                // Primer acceso: la cuenta todavía no tiene autenticador.
                case .needsSetup:
                    TotpSetupView()

                case .needsCode:
                    TotpView()

                case .signedIn:
                    MainTabView()
                }
            }
        }
        .task {
            // Restaura la sesión guardada: si hay tokens válidos entra directo,
            // si no, pasa a la pantalla de login.
            await session.restore()
        }
    }
}
