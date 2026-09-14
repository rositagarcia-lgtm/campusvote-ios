import SwiftUI

struct RootView: View {

    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.phase {

            case .checking:
                SplashView()

            case .signedOut:
                LoginView()

            case .needsCode:
                TotpView()

            case .signedIn:
                JuryDashboardView()
            }
        }
        .task {
            await startApp()
        }
    }

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
}