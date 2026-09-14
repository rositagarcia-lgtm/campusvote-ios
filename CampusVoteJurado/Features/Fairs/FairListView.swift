import SwiftUI

/// Pantalla 02 · Mis ferias. Es la raíz de la navegación: aquí se registran
/// todas las pantallas a las que se llega por valor.
struct FairListView: View {
    @Environment(SessionStore.self) private var session
    @Environment(FairsStore.self) private var fairs

    var body: some View {
        List {
            if let message = fairs.errorMessage {
                ErrorBanner(message: message)
            }
            ForEach(fairs.fairs) { fair in
                NavigationLink(value: fair) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fair.name)
                            .font(.headline)
                        Text(fair.statusLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay {
            if fairs.fairs.isEmpty && !fairs.isLoading && fairs.errorMessage == nil {
                ContentUnavailableView(
                    "Sin ferias asignadas",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Cuando el admin te asigne a una feria, aparecerá aquí.")
                )
            }
        }
        .navigationTitle("Mis ferias")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Salir") {
                    Task { await session.logout() }
                }
            }
        }
        .task { await fairs.load() }
        .refreshable { await fairs.load() }
        .navigationDestination(for: Fair.self) { fair in
            ProjectListView(fair: fair)
        }
        .navigationDestination(for: ProjectRoute.self) { route in
            ProjectDetailView(route: route)
        }
        .navigationDestination(for: EvaluateRoute.self) { route in
            EvaluateView(route: route)
        }
        .navigationDestination(for: ProgressRoute.self) { route in
            MyProgressView(fair: route.fair)
        }
    }
}
