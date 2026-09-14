import SwiftUI

/// Decide qué mostrar según el estado de la sesión.
struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        switch session.phase {
        case .checking:
            ProgressView("Abriendo CampusVote…")
                .task { await session.restore() }
        case .signedOut:
            LoginView()
        case .needsCode:
            TotpView()
        case .signedIn:
            NavigationStack {
                FairListView()
            }
        }
    }
}
