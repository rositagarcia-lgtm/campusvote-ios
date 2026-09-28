import SwiftUI

struct SearchView: View {
    @Environment(FairsStore.self) private var fairsStore
    @Environment(ProjectsStore.self) private var projectsStore

    @State private var selectedFairId: String?

    private var activeFairs: [FairAssignment] {
        fairsStore.activeFairs
    }

    private var fairId: String? {
        selectedFairId ?? activeFairs.first?.fair.id
    }

    private var selectedFairName: String {
        activeFairs.first { $0.fair.id == fairId }?.fair.name ?? "Feria"
    }

    var body: some View {
        Group {
            if activeFairs.isEmpty && fairsStore.isLoading {
                ProgressView("Cargando ferias...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if activeFairs.isEmpty {
                ContentUnavailableView(
                    "Sin ferias activas",
                    systemImage: "building.columns",
                    description: Text("Los proyectos aparecerán aquí cuando tengas una feria asignada.")
                )
            } else {
                content
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Buscar")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await fairsStore.fetchMyAssignments()
            if selectedFairId == nil {
                selectedFairId = activeFairs.first?.fair.id
            }
            if let fairId {
                await projectsStore.open(fairId: fairId)
            }
        }
        .onChange(of: selectedFairId) { _, _ in
            projectsStore.clearSearch()
            Task {
                if let fairId {
                    await projectsStore.open(fairId: fairId)
                    await projectsStore.searchProjects(fairId: fairId)
                }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if activeFairs.count > 1 {
                    fairPicker
                } else {
                    Text(selectedFairName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                searchCard
                filterCard
                counterRow
                results
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable { await refresh() }
        .task(id: projectsStore.searchRevision) {
            guard let fairId else { return }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await projectsStore.searchProjects(fairId: fairId)
        }
    }

    private var fairPicker: some View {
        Picker("Feria", selection: $selectedFairId) {
            ForEach(activeFairs) { assignment in
                Text(assignment.fair.name)
                    .tag(Optional(assignment.fair.id))
            }
        }
        .pickerStyle(.menu)
        .tint(Color.brand)
    }

    private var searchCard: some View {
        @Bindable var store = projectsStore

        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.brand)

            TextField("Nombre o stand", text: $store.searchText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)

            if !store.searchText.isEmpty {
                Button {
                    store.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpiar búsqueda")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }

    private var filterCard: some View {
        @Bindable var store = projectsStore

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FILTROS")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                Spacer()
                if store.searchCategoryId != nil || store.searchStandId != nil || !store.searchText.isEmpty {
                    Button("Limpiar") {
                        store.clearSearch()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
                }
            }

            filterRow(
                title: "Categoría",
                value: categoryName(store.searchCategoryId)
            ) {
                Picker("Categoría", selection: $store.searchCategoryId) {
                    Text("Todas").tag(String?.none)
                    ForEach(store.categories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
            }

            Divider()

            filterRow(
                title: "Stand",
                value: standName(store.searchStandId)
            ) {
                Picker("Stand", selection: $store.searchStandId) {
                    Text("Todos").tag(String?.none)
                    ForEach(store.stands) { stand in
                        Text(stand.code).tag(Optional(stand.id))
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func filterRow<Menu: View>(
        title: String,
        value: String,
        @ViewBuilder menu: () -> Menu
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            Spacer()
            menu()
                .labelsHidden()
                .tint(Color.brand)
        }
    }

    private func categoryName(_ id: String?) -> String {
        guard let id else { return "Todas" }
        return projectsStore.categories.first { $0.id == id }?.name ?? "Todas"
    }

    private func standName(_ id: String?) -> String {
        guard let id else { return "Todos" }
        return projectsStore.stands.first { $0.id == id }?.code ?? "Todos"
    }

    private var counterRow: some View {
        Text("\(projectsStore.searchResults.count) proyectos de tus categorías")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var results: some View {
        if let errorMessage = projectsStore.errorMessage {
            ErrorBanner(message: errorMessage)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        if projectsStore.isLoading && projectsStore.searchResults.isEmpty {
            ProgressView("Buscando proyectos...")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if projectsStore.searchResults.isEmpty {
            ContentUnavailableView(
                "Sin resultados",
                systemImage: "magnifyingglass",
                description: Text("Prueba otro nombre, otra categoría o otro stand.")
            )
            .frame(maxWidth: .infinity, minHeight: 220)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(projectsStore.searchResults) { result in
                    SearchResultRow(result: result, fairId: fairId ?? "")
                }
            }
        }
    }

    private func refresh() async {
        guard let fairId else { return }
        await projectsStore.open(fairId: fairId)
        await projectsStore.searchProjects(fairId: fairId)
    }
}

private struct SearchResultRow: View {
    let result: ProjectSearchResult
    let fairId: String

    var body: some View {
        NavigationLink(destination: ProjectDetailView(fairId: fairId, projectId: result.id)) {
            HStack(spacing: 12) {
                CoverImage(url: result.coverUrl.flatMap { URL(string: $0) })
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    Text(result.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if let standCode = result.standCode, !standCode.isEmpty {
                            Text(standCode)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.brandGold.opacity(0.2))
                                .foregroundStyle(Color.brandGold)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        if let category = result.categoryName, !category.isEmpty {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.brand.opacity(0.12))
                                .foregroundStyle(Color.brand)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
        }
        .buttonStyle(.plain)
    }
}
