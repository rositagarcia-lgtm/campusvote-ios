import SwiftUI

struct MainTabView: View {
    @Environment(TabBarVisibility.self) private var tabBar
    @State private var selectedTab: Int = 0

    /// Las cuatro secciones del jurado, en orden.
    private let pestanas: [(icono: String, titulo: String)] = [
        ("building.columns", "Ferias"),
        ("chart.bar.xaxis", "Mi avance"),
        ("magnifyingglass", "Buscar"),
        ("person.circle", "Perfil"),
    ]

    var body: some View {
        TabView(selection: $selectedTab) {

            FairListView()
                .toolbar(.hidden, for: .tabBar)
                .tag(0)

            NavigationStack {
                MiAvanceTab()
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(1)

            NavigationStack {
                SearchView()
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(2)

            NavigationStack {
                ProfileView()
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(3)
        }
        .tint(Color.appPrimary)
        .safeAreaInset(edge: .bottom, spacing: 0) {
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

/// Mi avance de la feria elegida. Si hay varias, el jurado cambia con el menú.
private struct MiAvanceTab: View {
    @Environment(FairsStore.self) private var fairsStore
    @State private var selectedFairId: String?

    private var fairs: [FairAssignment] {
        fairsStore.activeFairs + fairsStore.closedFairs
    }

    var body: some View {
        Group {
            if fairsStore.isLoading && fairs.isEmpty {
                ProgressView("Cargando ferias...")
            } else if fairs.isEmpty {
                ContentUnavailableView(
                    "Sin ferias",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Cuando tengas una feria asignada, aquí verás tu avance.")
                )
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    if fairs.count > 1 {
                        Picker("Feria", selection: $selectedFairId) {
                            ForEach(fairs) { assignment in
                                Text(assignment.fair.name)
                                    .tag(Optional(assignment.fair.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    if let fairId = selectedFairId {
                        MyProgressView(fairId: fairId)
                            .id(fairId)
                    }
                }
            }
        }
        .task {
            await fairsStore.fetchMyAssignments()
            if selectedFairId == nil {
                selectedFairId = fairs.first?.fair.id
            }
        }
    }
}
