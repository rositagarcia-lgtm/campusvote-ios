import SwiftUI

/// Todos los proyectos aprobados de una feria abierta.
/// GET /projects?fair_id=... filtra por organización y estado APPROVED.
struct AllProjectsView: View {
    @Environment(\.locale) private var locale
    let onSelect: (Project) -> Void

    @Environment(ProjectsStore.self) private var store
    @Environment(ProjectsCatalogStore.self) private var catalog
    @Environment(FairsStore.self) private var fairs

    @State private var fairId: String?
    @State private var search = ""

    private var filtered: [Project] {
        let text = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return catalog.projects }
        return catalog.projects.filter { project in
            project.name.localizedCaseInsensitiveContains(text)
                || (project.categoryName?.localizedCaseInsensitiveContains(text) ?? false)
                || (project.standCode?.localizedCaseInsensitiveContains(text) ?? false)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if fairs.activeFairs.isEmpty {
                    emptyState(
                        icon: "calendar.badge.exclamationmark",
                        title: "No hay ferias abiertas",
                        message: "Los proyectos se habilitan cuando la feria está abierta."
                    )
                } else {
                    fairChips
                    searchField
                    content
                }
            }
            .padding(18)
        }
        .task {
            let initial = fairId ?? fairs.activeFairs.first?.fair.id
            fairId = initial
            if let initial {
                await catalog.load(fairId: initial)
            }
        }
        .refreshable { await reload() }
    }

    private var fairChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(fairs.activeFairs) { assignment in
                    let selected = fairId == assignment.fair.id
                    Button {
                        guard fairId != assignment.fair.id else { return }
                        fairId = assignment.fair.id
                        Task { await catalog.load(fairId: assignment.fair.id) }
                    } label: {
                        Text(assignment.fair.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .foregroundStyle(selected ? Color.onBrand : Color.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(selected ? Color.brand : Color.cardBackground))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(Color.appNeutral)
            TextField("Buscar proyecto, categoría o stand", text: $search)
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

    @ViewBuilder
    private var content: some View {
        if catalog.isLoading && catalog.projects.isEmpty {
            ProgressView("Cargando proyectos...")
                .frame(maxWidth: .infinity, minHeight: 160)
        } else if let message = catalog.errorMessage, catalog.projects.isEmpty {
            VStack(spacing: 10) {
                ErrorBanner(message: message)
                Button("Reintentar") {
                    Task { await reload() }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brand)
            }
            .frame(maxWidth: .infinity)
        } else if filtered.isEmpty {
            emptyState(
                icon: "tray",
                title: "Sin proyectos aprobados",
                message: "Esta feria todavía no tiene proyectos aceptados."
            )
        } else {
            LazyVStack(spacing: 10) {
                ForEach(filtered) { project in
                    AllProjectRow(project: project, isAssigned: store.isAssigned(projectId: project.id)) {
                        onSelect(project)
                    }
                }
            }
        }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.brand)
            Text(L10n.tr(title, locale: locale))
                .font(.subheadline.weight(.semibold))
            Text(L10n.tr(message, locale: locale))
                .font(.caption)
                .foregroundStyle(Color.appNeutral)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func reload() async {
        guard let fairId else { return }
        await catalog.load(fairId: fairId)
    }
}

private struct AllProjectRow: View {
    @Environment(\.locale) private var locale
    let project: Project
    let isAssigned: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                thumbnail

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        if let category = project.categoryName {
                            Text(category)
                                .lineLimit(1)
                        }
                        if let stand = project.standCode {
                            Text(L10n.format("Stand %@", locale: locale, stand))
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color.appNeutral)
                }

                Spacer(minLength: 0)

                if isAssigned {
                    Text("Asignado")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.brand.opacity(0.12)))
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appNeutral)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnail: some View {
        let urlString = project.coverUrl ?? project.logoUrl
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    placeholder
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            placeholder
                .frame(width: 54, height: 54)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.brand.opacity(0.1))
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(Color.brand)
            }
    }
}
