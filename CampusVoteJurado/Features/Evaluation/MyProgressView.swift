import SwiftUI

/// Avance del jurado. El encabezado se mantiene. El cuerpo es el resumen y las tarjetas.
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

    private var institutionName: String {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return fairsStore.organizationName ?? "Institución"
    }

    private var listMatchesFair: Bool {
        projectsStore.fairId == selectedFairId
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                progressRing

                VStack(alignment: .leading, spacing: 8) {
                    Text(fairName.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .lineLimit(2)

                    Text("Evaluación de Proyectos")
                        .font(.subheadline.weight(.semibold))

                    statusPill(
                        text: ratedCount == 1 ? "1 completado" : "\(ratedCount) completados",
                        color: Color(red: 0.13, green: 0.62, blue: 0.36)
                    )
                    statusPill(
                        text: pendingCount == 1
                            ? "1 pendiente de calificación"
                            : "\(pendingCount) pendientes de calificación",
                        color: Color(red: 0.85, green: 0.45, blue: 0.12)
                    )
                }
            }

            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Color.brandGold)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(averageText)
                            .font(.subheadline.weight(.semibold))
                        Text("calificación promedio\notorgada")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(institutionName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .lineLimit(1)
                    Text("Jurados")
                        .font(.caption2)
                        .foregroundStyle(Color.brand)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.brand.opacity(0.1)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.brand.opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.brand, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(ratedCount)/\(totalCount)")
                    .font(.caption.weight(.semibold))
                Text("\(percent)%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 64, height: 64)
    }

    private func statusPill(text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.12)))
    }

    private var selector: some View {
        HStack(spacing: 10) {
            filterButton(
                title: "Pendientes",
                count: pendingCount,
                selected: !showsRated
            ) {
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
                Text(title)
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.brand : Color.primary.opacity(0.12), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
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

private struct PendingProjectCard: View {
    let project: ReviewProject

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let category = project.categoryName, !category.isEmpty {
                            Text(category.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(red: 0.85, green: 0.45, blue: 0.12))
                                .frame(width: 6, height: 6)
                            Text("Pendiente")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.12))
                        }
                    }

                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
            }

            HStack {
                Text("Sin reseña aún")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                    Text("Evaluar")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.onBrand)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.brand))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }
}

private struct RatedProjectCard: View {
    let project: ReviewProject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                        Text("Evaluado")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(Color(red: 0.13, green: 0.62, blue: 0.36))

                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let category = project.categoryName, !category.isEmpty {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 6) {
                if let rating = project.myRating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(star <= rating ? Color.brandGold : Color.appNeutral)
                        }
                    }
                    Text(String(format: "%.1f", Double(rating)))
                        .font(.caption.weight(.semibold))
                }
                Spacer(minLength: 8)
                Text("Editar reseña >")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }

            if let comment = project.myComment, !comment.isEmpty {
                Text("\"\(comment)\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }
}
