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

<<<<<<< HEAD
            case .signedIn:
                JuryDashboardView()
=======
                case .needsCode:
                    TotpView()

                case .signedIn:
                    MainTabView()
                }
>>>>>>> c26b2aa (fix: codikey por Json)
            }
        }
        .task {
            // Restaura la sesión guardada: si hay tokens válidos entra directo,
            // si no, pasa a la pantalla de login.
            await session.restore()
        }
    }
<<<<<<< HEAD

    @MainActor
    private func startApp() async {

        // Esperamos mientras se muestra la pantalla de carga.
        try? await Task.sleep(for: .seconds(2))

        // Si durante estos 2 segundos el estado cambió,
        // no hacemos nada.
        guard session.phase == .checking else {
            return
        }

        // Después del splash vamos al Login.
        session.showLogin()
    }
=======
>>>>>>> c26b2aa (fix: codikey por Json)
}