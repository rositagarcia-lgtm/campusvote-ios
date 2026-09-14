import SwiftUI

struct MainTabView: View {
    @Environment(FairsStore.self) private var fairsStore
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: - Tab 1: Ferias
            NavigationStack {
                FairListView()
            }
            .tabItem {
                Label("Ferias", systemImage: "building.columns")
            }
            .tag(0)

            // MARK: - Tab 2: Buscar (proyectos de una feria)
            NavigationStack {
                SearchProjectsView()
            }
            .tabItem {
                Label("Buscar", systemImage: "magnifyingglass")
            }
            .tag(1)

            // MARK: - Tab 3: Perfil
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.circle")
            }
            .tag(2)
        }
        .tint(Color.appPrimary)
    }
}

/// Buscador de proyectos sobre una feria activa elegida por el jurado.
private struct SearchProjectsView: View {
    @Environment(FairsStore.self) private var fairsStore
    @State private var selectedFairId: String?

    private var activeFairs: [FairAssignment] {
        fairsStore.activeFairs
    }

    var body: some View {
        Group {
            if fairsStore.isLoading && activeFairs.isEmpty {
                ProgressView("Cargando ferias...")
            } else if activeFairs.isEmpty {
                ContentUnavailableView(
                    "Sin ferias activas",
                    systemImage: "magnifyingglass",
                    description: Text("Ve a la pestaña Ferias para ver tus asignaciones.")
                )
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Picker("Feria", selection: $selectedFairId) {
                        ForEach(activeFairs) { assignment in
                            Text(assignment.fair.name)
                                .tag(Optional(assignment.fair.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .padding(.bottom, 4)

                    if let fairId = selectedFairId {
                        ProjectListView(fairId: fairId, showsFairsBack: false)
                    }
                }
                .onAppear {
                    if selectedFairId == nil {
                        selectedFairId = activeFairs.first?.fair.id
                    }
                }
            }
        }
        .navigationTitle("Buscar")
        .task {
            await fairsStore.fetchMyAssignments()
        }
    }
}