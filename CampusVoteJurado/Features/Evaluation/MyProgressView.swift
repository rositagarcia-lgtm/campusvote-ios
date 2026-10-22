import SwiftUI

/// Avance del jurado. El encabezado se mantiene. El cuerpo es el resumen y las tarjetas.
struct MyProgressView: View {
    var fairId: String? = nil

    @Environment(\.locale) private var locale
    @Environment(ProjectsStore.self) private var projectsStore
    @Environment(FairsStore.self) private var fairsStore
    @State private var selectedFairId: String?
    @State private var showsRated = false

    private var openFairs: [FairAssignment] {
        fairsStore.activeFairs
    }

    private var fairName: String {
        openFairs.first { $0.fair.id == selectedFairId }?.fair.name ?? L10n.tr("Feria", locale: locale)
    }

    private var institutionName: String {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return "CampusVote"
    }

    private var listMatchesFair: Bool {
        projectsStore.fairId == selectedFairId && projectsStore.scope == .assigned
    }

    private var ratedCount: Int {
        listMatchesFair ? projectsStore.summary.rated : 0
    }

    private var totalCount: Int {
        listMatchesFair ? projectsStore.summary.total : 0
    }

    private var pendingCount: Int {
        listMatchesFair ? projectsStore.pending.count : 0
    }

    private var fraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(ratedCount) / Double(totalCount)
    }

    private var percent: Int {
        Int((fraction * 100).rounded())
    }

    private var averageText: String {
        let ratings = listMatchesFair ? projectsStore.rated.compactMap(\.myRating) : []
        guard !ratings.isEmpty else { return "—" }
        let value = Double(ratings.reduce(0, +)) / Double(ratings.count)
        return String(format: "%.1f", value)
    }

    private var visibles: [ReviewProject] {
        guard listMatchesFair else { return [] }
        return showsRated ? projectsStore.rated : projectsStore.pending
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if openFairs.count > 1 {
                fairMenu
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let message = projectsStore.errorMessage ?? fairsStore.errorMessage {
                        ScreenStateView(icon: "exclamationmark.triangle", title: "No pudimos cargar tu avance",
                                        message: message, actionTitle: "Reintentar") {
                            Task {
                                await fairsStore.fetchMyAssignments()
                                selectedFairId = selectedFairId ?? fairsStore.activeFairs.first?.id
                                if let selectedFairId { await projectsStore.load(fairId: selectedFairId) }
                            }
                        }
                    }

                    if selectedFairId == nil && !fairsStore.isLoading {
                        emptyState(
                            title: "Sin ferias abiertas",
                            message: "Cuando tengas una feria abierta, aquí verás tu avance.",
                            systemImage: "chart.bar"
                        )
                    } else if projectsStore.isLoading && !listMatchesFair {
                        ProgressView("Cargando tu avance...")
                            .frame(maxWidth: .infinity, minHeight: 180)
                    } else if listMatchesFair {
                        MyProgressSummaryCard(
                            fairName: fairName,
                            institutionName: institutionName,
                            ratedCount: ratedCount,
                            totalCount: totalCount,
                            pendingCount: pendingCount,
                            fraction: fraction,
                            percent: percent,
                            averageText: averageText
                        )
                        selector

                        if visibles.isEmpty {
                            emptyState(
                                title: showsRated ? "Sin reseñas" : "Nada pendiente",
                                message: showsRated
                                    ? "Cuando guardes estrellas y un comentario, el proyecto aparece aquí."
                                    : "Ya dejaste reseña en todos los proyectos de esta feria.",
                                systemImage: showsRated ? "star" : "checkmark.circle"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(visibles) { project in
                                    if let fairId = selectedFairId {
                                        NavigationLink {
                                            ProjectDetailView(fairId: fairId, projectId: project.id)
                                        } label: {
                                            if project.sinResena {
                                                PendingProjectCard(project: project)
                                            } else {
                                                RatedProjectCard(project: project)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .refreshable {
                guard let selectedFairId else { return }
                await projectsStore.load(fairId: selectedFairId)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if fairsStore.activeFairs.isEmpty {
                await fairsStore.fetchMyAssignments()
            }
            guard selectedFairId == nil else { return }
            let preferred = fairId.flatMap { id in
                fairsStore.activeFairs.first { $0.fair.id == id }?.fair.id
            }
            selectedFairId = preferred ?? fairsStore.activeFairs.first?.fair.id
        }
        .task(id: selectedFairId) {
            guard let selectedFairId else { return }
            await projectsStore.load(fairId: selectedFairId)
        }
        .onAppear {
            guard let selectedFairId, !listMatchesFair else { return }
            Task { await projectsStore.load(fairId: selectedFairId) }
        }
    }

    private var header: some View { OrganizationHeader(title: "Avance") }

    private var fairMenu: some View {
        Menu {
            ForEach(openFairs) { assignment in
                Button(assignment.fair.name) {
                    selectedFairId = assignment.fair.id
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(fairName)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.brand)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
    }

    private var selector: some View {
        HStack(spacing: 10) {
            filterButton(title: "Pendientes", count: pendingCount, selected: !showsRated) {
                showsRated = false
            }
            filterButton(
                title: "Con reseña",
                count: listMatchesFair ? projectsStore.rated.count : 0,
                selected: showsRated
            ) {
                showsRated = true
            }
        }
    }

    private func filterButton(title: String, count: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(L10n.tr(title, locale: locale))
                    .font(.subheadline.weight(.semibold))
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(selected ? Color.onBrand : .secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(selected ? Color.brand : Color.primary.opacity(0.08)))
            }
            .foregroundStyle(selected ? Color.brand : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.brand : Color.primary.opacity(0.12), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        ScreenStateView(icon: systemImage, title: title, message: message)
    }
}
