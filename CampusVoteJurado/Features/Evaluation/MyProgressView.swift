import SwiftUI

/// Avance del jurado. El encabezado se mantiene. El cuerpo es el resumen y las tarjetas.
struct MyProgressView: View {
    var fairId: String? = nil

    @Environment(\.locale) private var locale
    @Environment(ProjectsStore.self) private var projectsStore
    @Environment(FairsStore.self) private var fairsStore
    @State private var selectedFairId: String?
    @State private var showsRated = false
    @State private var showsFairMenu = false
    @State private var closedFairCardHeight: CGFloat = 88

    private var openFairs: [FairAssignment] {
        fairsStore.activeFairs
    }

    private var fairName: String {
        openFairs.first { $0.fair.id == selectedFairId }?.fair.name ?? L10n.tr("Feria", locale: locale)
    }

    private var showsFairSelector: Bool {
        selectedFairId != nil || !openFairs.isEmpty
    }

    private var institutionName: String {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return "CampusVote"
    }

    private var listMatchesFair: Bool {
        projectsStore.fairId == selectedFairId && projectsStore.scope == .assigned
    }

    /// La feria nueva todavía no tiene respuesta. La lista de abajo espera.
    /// Si recargas la misma feria, los proyectos se quedan visibles.
    private var listIsLoading: Bool {
        guard selectedFairId != nil else { return projectsStore.isLoading }
        if !listMatchesFair { return true }
        return projectsStore.isLoading && projectsStore.projects.isEmpty
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

            ZStack(alignment: .top) {
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
                        } else if selectedFairId == nil {
                            loadingList
                        } else {
                            if listMatchesFair {
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
                            }
                            selector

                            if listIsLoading {
                                loadingList
                            } else if visibles.isEmpty {
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
                .padding(.top, showsFairSelector ? closedFairCardHeight : 0)
                .refreshable {
                    guard let selectedFairId else { return }
                    await projectsStore.load(fairId: selectedFairId)
                }

                if showsFairMenu {
                    Color.black.opacity(0.28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { closeFairMenu() }
                }

                if showsFairSelector {
                    fairMenu
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onPreferenceChange(FairCardHeightKey.self) { closedFairCardHeight = $0 }
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

    private var loadingList: some View {
        ProgressView()
            .frame(maxWidth: .infinity, minHeight: 180)
    }

    private var fairMenu: some View {
        VStack(spacing: 0) {
            Button {
                guard openFairs.count > 1 else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsFairMenu.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.brand.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr("Feria actual", locale: locale))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(fairName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    if openFairs.count > 1 {
                        Image(systemName: showsFairMenu ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: FairCardHeightKey.self,
                        value: proxy.size.height + 20
                    )
                }
            )

            if showsFairMenu && openFairs.count > 1 {
                Divider().padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(openFairs) { assignment in
                        let isSelected = assignment.fair.id == selectedFairId

                        Button {
                            selectedFairId = assignment.fair.id
                            closeFairMenu()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isSelected ? "checkmark" : "circle")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color.brand : Color.secondary.opacity(0.45))
                                    .frame(width: 22, height: 22)

                                Text(assignment.fair.name)
                                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? Color.brand : .primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if assignment.id != openFairs.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .premiumSurface(raised: showsFairMenu)
        .zIndex(2)
    }

    private func closeFairMenu() {
        guard showsFairMenu else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showsFairMenu = false
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

private struct FairCardHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 88
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
