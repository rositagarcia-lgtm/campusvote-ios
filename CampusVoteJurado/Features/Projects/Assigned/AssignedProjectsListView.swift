import SwiftUI

/// Lista de proyectos asignados al jurado para reseñar.
/// GET /fairs/my-projects ya devuelve solo aprobados de sus categorías.
struct AssignedProjectsListView: View {
    @Environment(\.locale) private var locale
    let onSelect: (ReviewProject) -> Void

    @Environment(ProjectsStore.self) private var store

    @State private var search = ""
    @State private var filter: AssignedFilter = .pending

    private var filtered: [ReviewProject] {
        let text = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.assignedProjects.filter { project in
            let matchesFilter: Bool
            switch filter {
            case .pending: matchesFilter = project.sinResena
            case .rated: matchesFilter = !project.sinResena
            case .all: matchesFilter = true
            }
            let matchesText = text.isEmpty
                || project.name.localizedCaseInsensitiveContains(text)
                || (project.categoryName?.localizedCaseInsensitiveContains(text) ?? false)
                || (project.fairName?.localizedCaseInsensitiveContains(text) ?? false)
            return matchesFilter && matchesText
        }
    }

    private var grouped: [(fair: String, projects: [ReviewProject])] {
        var order: [String] = []
        var map: [String: [ReviewProject]] = [:]
        for project in filtered {
            let key = project.fairName ?? L10n.tr("Feria", locale: locale)
            if map[key] == nil { order.append(key) }
            map[key, default: []].append(project)
        }
        return order.map { (fair: $0, projects: map[$0] ?? []) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if store.isLoadingAssigned && store.assignedProjects.isEmpty {
                    ProgressView("Cargando tus proyectos...")
                        .frame(maxWidth: .infinity, minHeight: 220)
                } else if let message = store.assignedErrorMessage,
                          store.assignedProjects.isEmpty {
                    ScreenStateView(
                        icon: "wifi.exclamationmark",
                        title: "No pudimos cargar tus proyectos",
                        message: message,
                        actionTitle: "Reintentar"
                    ) {
                        Task { await store.loadAssigned() }
                    }
                } else {
                    if let message = store.assignedErrorMessage {
                        ErrorBanner(message: message)
                    }

                    AssignedSummaryCard(
                        rated: store.assignedSummary.rated,
                        total: store.assignedSummary.total,
                        pending: store.assignedSummary.pending
                    )
                    searchField
                    filterChips
                    content
                }
            }
            .padding(18)
        }
        .refreshable { await store.loadAssigned() }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(Color.appNeutral)
            TextField("Buscar proyecto, categoría o feria", text: $search)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.appNeutral)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpiar búsqueda")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .premiumSurface(cornerRadius: 12)
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(AssignedFilter.allCases) { item in
                Button { filter = item } label: {
                    Text(L10n.tr(item.title, locale: locale))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(filter == item ? Color.onBrand : Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: 44)
                        .background(Capsule().fill(filter == item ? Color.brand : Color.cardBackground))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(filter == item ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            emptyState
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(grouped, id: \.fair) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.fair.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(Color.appNeutral)
                        ForEach(group.projects) { project in
                            AssignedProjectRow(project: project) {
                                onSelect(project)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ScreenStateView(
            icon: search.isEmpty ? "checklist" : "magnifyingglass",
            title: search.isEmpty ? "Sin proyectos en esta vista" : "Sin resultados",
            message: search.isEmpty
                ? "Cuando te asignen proyectos en una feria abierta, aparecerán aquí."
                : "Prueba con otro nombre, categoría o feria."
        )
    }
}

private enum AssignedFilter: String, CaseIterable, Identifiable {
    case pending
    case rated
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "Pendientes"
        case .rated: return "Reseñados"
        case .all: return "Todos"
        }
    }
}
