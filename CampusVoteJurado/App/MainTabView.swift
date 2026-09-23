import SwiftUI

struct MainTabView: View {
    @Environment(FairsStore.self) private var fairsStore
    @Environment(TabBarVisibility.self) private var tabBar
    @State private var selectedTab: Int = 0

    /// Las tres secciones del jurado, en orden.
    private let pestanas: [(icono: String, titulo: String)] = [
        ("building.columns", "Ferias"),
        ("magnifyingglass", "Buscar"),
        ("person.circle", "Perfil"),
    ]

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: - Tab 1: Ferias
            // Sin NavigationStack aquí: FairListView trae el suyo (con su
            // propio path). Envolverla en otro deja una barra vacía arriba.
            FairListView()
                .toolbar(.hidden, for: .tabBar)
                .tag(0)

            // MARK: - Tab 2: Buscar (proyectos de una feria)
            NavigationStack {
                SearchProjectsView()
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(1)

            // MARK: - Tab 3: Perfil
            NavigationStack {
                ProfileView()
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(2)
        }
        .tint(Color.appPrimary)
        // La barra nativa agrupa los iconos al centro. Esta ocupa todo el
        // ancho: cada sección se lleva la misma porción de la pantalla.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // La declaración de conflicto de interés se firma sin la barra.
            if !tabBar.isHidden {
                barraInferior
            }
        }
    }

    private var barraInferior: some View {
        HStack(spacing: 0) {
            ForEach(Array(pestanas.enumerated()), id: \.offset) { indice, pestana in
                Button {
                    selectedTab = indice
                } label: {
                    TabBarItem(
                        icon: pestana.icono,
                        label: pestana.titulo,
                        isSelected: selectedTab == indice,
                        activeColor: Color.appPrimary
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(pestana.titulo)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(
            Color.cardBackground
                .overlay(alignment: .top) { Divider() }
                .ignoresSafeArea(edges: .bottom)
        )
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
