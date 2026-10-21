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
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
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
                        .background(Capsule().fill(filter == item ? Color.brand : Color.cardBackground))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoadingAssigned && store.assignedProjects.isEmpty {
            ProgressView("Cargando tus proyectos...")
                .frame(maxWidth: .infinity, minHeight: 160)
        } else if filtered.isEmpty {
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
        VStack(spacing: 10) {
            Image(systemName: "checklist")
                .font(.title2)
                .foregroundStyle(Color.brand)
            Text("Sin proyectos en esta vista")
                .font(.subheadline.weight(.semibold))
            Text("Cuando te asignen proyectos en una feria abierta, aparecerán aquí.")
                .font(.caption)
                .foregroundStyle(Color.appNeutral)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
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
