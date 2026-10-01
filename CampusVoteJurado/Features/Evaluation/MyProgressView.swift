import SwiftUI

/// Avance del jurado. Sale de review-projects: pendientes sin my_rating y reseñados con estrellas.
struct MyProgressView: View {
    var fairId: String? = nil

    @Environment(ProjectsStore.self) private var projectsStore
    @Environment(FairsStore.self) private var fairsStore
    @State private var selectedFairId: String?
    @State private var showsRated = false

    private var openFairs: [FairAssignment] {
        fairsStore.activeFairs
    }

    private var fairName: String {
        openFairs.first { $0.fair.id == selectedFairId }?.fair.name ?? "Feria"
    }

    private var listMatchesFair: Bool {
        projectsStore.fairId == selectedFairId
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
                        ErrorBanner(message: message)
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
                        summaryCard
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
                                            ProgressProjectCard(project: project)
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
    }

    private var header: some View {
        VStack(spacing: 0) {
            Text("Avance")
                .font(.headline)
                .foregroundStyle(Color.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            Rectangle()
                .fill(Color.onBrand.opacity(0.35))
                .frame(height: 0.5)
        }
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

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

    private var summaryCard: some View {
        let rated = projectsStore.summary.rated
        let total = projectsStore.summary.total
        let fraction = total == 0 ? 0 : Double(rated) / Double(total)

        return VStack(alignment: .leading, spacing: 10) {
            Text("\(rated) de \(total)")
                .font(.headline)
            Text(openFairs.count > 1 ? "proyectos con reseña" : fairName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.iconTile)
                    Capsule()
                        .fill(Color.brand)
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private var selector: some View {
        HStack(spacing: 0) {
            TabSegmentButton(
                title: "Pendientes",
                count: listMatchesFair ? projectsStore.pending.count : 0,
                isSelected: !showsRated,
                activeColor: Color.brand,
                activeBadgeColor: Color.appPrimaryLight
            ) {
                showsRated = false
            }
            TabSegmentButton(
                title: "Con reseña",
                count: listMatchesFair ? projectsStore.rated.count : 0,
                isSelected: showsRated,
                activeColor: Color.brand,
                activeBadgeColor: Color.appPrimaryLight
            ) {
                showsRated = true
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.iconTile))
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.brand)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

private struct ProgressProjectCard: View {
    let project: ReviewProject

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if let category = project.categoryName, !category.isEmpty {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let rating = project.myRating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(star <= rating ? Color.brandGold : Color.appNeutral)
                        }
                    }
                    if let comment = project.myComment, !comment.isEmpty {
                        Text(comment)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                } else {
                    Text("Sin reseña")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brand)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }
}
