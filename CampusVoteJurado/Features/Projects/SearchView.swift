import SwiftUI

/// Buscador de proyectos en modo observador (solo lectura).
/// Usa el diseño Stitch: JuryTheme, JuryTypography y componentes reutilizables.
struct SearchView: View {
    @Environment(FairsStore.self) private var fairsStore
    @Environment(ProjectsStore.self) private var projectsStore
    @Environment(SessionStore.self) private var session

    @State private var selectedFairId: String?
    @State private var showFilters = false

    private var activeFairs: [FairAssignment] {
        fairsStore.activeFairs
    }

    private var fairId: String? {
        selectedFairId ?? activeFairs.first?.fair.id
    }

    private var sessionUser: User? {
        if case .signedIn(let user) = session.phase {
            return user
        }
        return nil
    }

    private var initials: String {
        guard let user = sessionUser else { return "?" }
        return "\(user.firstName.prefix(1))\(user.lastName.prefix(1))".uppercased()
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
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
        .sheet(isPresented: $showFilters) {
            FiltersSheet(store: projectsStore)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Contenido

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                fairPicker

                searchBar

                activeFilterChips

                counterRow

                results
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
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

    // MARK: - Encabezado

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                JuryTypography.eyebrow("CAMPUSVOTE · OBSERVADOR")
                    .foregroundStyle(.secondary)
                JuryTypography.display("Buscar")
                    .foregroundStyle(JuryTheme.brandDeep)
            }
            Spacer()
            ProfileCircle(initials: initials, size: 44)
        }
    }

    // MARK: - Selector de feria

    private var fairPicker: some View {
        Picker("Feria", selection: $selectedFairId) {
            ForEach(activeFairs) { assignment in
                Text(assignment.fair.name)
                    .tag(Optional(assignment.fair.id))
            }
        }
        .pickerStyle(.menu)
        .tint(JuryTheme.brandDeep)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Barra de búsqueda

    @ViewBuilder
    private var searchBar: some View {
        @Bindable var store = projectsStore

        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Buscar proyecto o stand...", text: $store.searchText)
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
                .accessibilityLabel("Limpiar búsqueda")
            }

            Divider()
                .frame(height: 18)

            Button {
                showFilters = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(JuryTheme.brandDeep)
            }
            .accessibilityLabel("Filtros")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Chips de filtros activos

    @ViewBuilder
    private var activeFilterChips: some View {
        let chips = buildActiveChips()

        if !chips.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips) { chip in
                        FilterChip(label: chip.label) {
                            chip.onRemove()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func buildActiveChips() -> [ActiveChip] {
        var chips: [ActiveChip] = []

        if let categoryId = projectsStore.searchCategoryId,
           let category = projectsStore.categories.first(where: { $0.id == categoryId }) {
            chips.append(
                ActiveChip(label: category.name) {
                    projectsStore.searchCategoryId = nil
                }
            )
        }
        if let minScore = projectsStore.minScore {
            chips.append(
                ActiveChip(label: "Nota ≥ \(minScore.formatted(.number.precision(.fractionLength(0...1))))") {
                    projectsStore.minScore = nil
                }
            )
        }
        if let maxScore = projectsStore.maxScore {
            chips.append(
                ActiveChip(label: "Nota ≤ \(maxScore.formatted(.number.precision(.fractionLength(0...1))))") {
                    projectsStore.maxScore = nil
                }
            )
        }

        return chips
    }

    // MARK: - Contador

    private var counterRow: some View {
        HStack {
            Text("\(projectsStore.searchResults.count) proyectos encontrados")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Text("MODO OBSERVADOR")
                .font(.caption2.bold())
                .tracking(1)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Resultados

    @ViewBuilder
    private var results: some View {
        if let errorMessage = projectsStore.errorMessage {
            ErrorBanner(message: errorMessage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }

        if projectsStore.isLoading && projectsStore.searchResults.isEmpty {
            ProgressView("Buscando proyectos...")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if projectsStore.searchResults.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("No se encontraron proyectos con estos filtros")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(projectsStore.searchResults) { result in
                    SearchResultRow(result: result, fairId: fairId ?? "")
                }
            }
        }

        footerNote
    }

    // MARK: - Pie

    private var footerNote: some View {
        Label(
            "Como observador institucional, la vista de notas es de solo lectura y se sincroniza en tiempo real con las actas.",
            systemImage: "checkmark.shield.fill"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: - Acciones

    private func refresh() async {
        guard let fairId else { return }
        await projectsStore.open(fairId: fairId)
        await projectsStore.searchProjects(fairId: fairId)
    }
}

// MARK: - Chip de filtro activo (con X para remover)

private struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(JuryTheme.mintText)
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(JuryTheme.mintText)
            }
            .accessibilityLabel("Quitar filtro \(label)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(JuryTheme.mint))
    }
}

private struct ActiveChip: Identifiable {
    let id = UUID()
    let label: String
    let onRemove: () -> Void
}

// MARK: - Hoja de filtros

private struct FiltersSheet: View {
    let store: ProjectsStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section("Categoría") {
                    Picker("Categoría", selection: $store.searchCategoryId) {
                        Text("Todas").tag(String?.none)
                        ForEach(store.categories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                }

                Section("Rango de nota") {
                    HStack {
                        Text("Mínima")
                        Spacer()
                        Text("\(Int(store.minScore ?? 0))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { store.minScore ?? 0 },
                            set: { store.minScore = $0 == 0 ? nil : $0 }
                        ),
                        in: 0...20,
                        step: 0.5
                    )

                    HStack {
                        Text("Máxima")
                        Spacer()
                        Text("\(Int(store.maxScore ?? 20))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { store.maxScore ?? 20 },
                            set: { store.maxScore = $0 == 20 ? nil : $0 }
                        ),
                        in: 0...20,
                        step: 0.5
                    )
                }

                Section("Ordenar por") {
                    Picker("Orden", selection: $store.sortBy) {
                        ForEach(SearchSort.allCases) { sort in
                            Text(sort.label).tag(sort)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Limpiar") {
                        store.clearSearch()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Fila de resultado

private struct SearchResultRow: View {
    let result: ProjectSearchResult
    let fairId: String

    var body: some View {
        NavigationLink(destination: ProjectDetailView(fairId: fairId, projectId: result.id)) {
            HStack(spacing: 14) {
                CoverImage(url: result.coverUrl.flatMap { URL(string: $0) })
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 6) {
                    Text(result.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let standCode = result.standCode, !standCode.isEmpty {
                        Text("Stand \(standCode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let category = result.categoryName {
                        Chip(text: category, background: JuryTheme.surface, textColor: Color.secondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    if let average = result.averageScore {
                        Text(average.formatted(.number.precision(.fractionLength(1))))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(JuryTheme.brandDeep)
                        Text("\(result.ratingsCount ?? 0) cal.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("—")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    SearchView()
        .environment(FairsStore(api: APIClient.shared))
        .environment(ProjectsStore(api: APIClient.shared))
        .environment(SessionStore(api: APIClient.shared))
}
