import SwiftUI

struct RankingView: View {
    let fairId: String
    let categoryId: String?

    @Environment(FairsStore.self) private var fairsStore
    @Environment(RankingStore.self) private var rankingStore

    @State private var selectedTab = 0

    private var fair: Fair? {
        fairsStore.activeFairs
            .first(where: { $0.fair.id == fairId })?
            .fair
    }

    private var selectedCategory: Category? {
        guard let categoryId else {
            return nil
        }

        return rankingStore.categories.first {
            $0.id == categoryId
        }
    }

    private var filteredProjects: [ProjectCard] {
        guard let categoryId else {
            return rankingStore.projects
        }

        return rankingStore.projects.filter {
            $0.categoryId == categoryId
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                header

                if rankingStore.isLoading {
                    ProgressView("Cargando información...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if let error = rankingStore.errorMessage {
                    errorView(error)
                } else {
                    content
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ranking provisional")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await rankingStore.load(fairId: fairId)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ranking provisional")
                        .font(.title2.bold())

                    Text(fair?.name ?? "Feria de proyectos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)

                    Text("EN VIVO")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }

            if let category = selectedCategory {
                Text(category.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            } else {
                Text("\(filteredProjects.count) proyectos")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {

            tabs

            switch selectedTab {
            case 0:
                generalRanking

            case 1:
                criteriaView

            default:
                myVotesView
            }

            footerInfo
        }
    }

    // MARK: - Tabs

    private var tabs: some View {
        Picker("Vista", selection: $selectedTab) {
            Text("Tabla General")
                .tag(0)

            Text("Por Criterios")
                .tag(1)

            Text("Mis Votos")
                .tag(2)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - General

    private var generalRanking: some View {
        VStack(alignment: .leading, spacing: 12) {

            sectionTitle(
                title: "Tabla general",
                subtitle: "Resultados consolidados de la feria"
            )

            notice(
                icon: "info.circle",
                text: "Los puntajes generales se mostrarán cuando el backend habilite los resultados consolidados de todos los jurados."
            )

            if filteredProjects.isEmpty {
                emptyView(
                    title: "No hay proyectos",
                    message: "No se encontraron proyectos para esta categoría."
                )
            } else {
                ForEach(
                    Array(filteredProjects.enumerated()),
                    id: \.element.id
                ) { index, project in

                    RankingProjectRow(
                        position: index + 1,
                        project: project
                    )
                }
            }
        }
    }

    // MARK: - Criteria

    private var criteriaView: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionTitle(
                title: "Criterios de evaluación",
                subtitle: "Rúbrica utilizada en esta feria"
            )

            if let rubric = rankingStore.rubric {
                ForEach(rubric.orderedCriteria) { criterion in
                    CriterionRow(criterion: criterion)
                }
            } else {
                emptyView(
                    title: "Rúbrica no disponible",
                    message: "No se pudo cargar la rúbrica de esta feria."
                )
            }
        }
    }

    // MARK: - My Votes

    private var myVotesView: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionTitle(
                title: "Mis votos",
                subtitle: "Evaluaciones realizadas por ti"
            )

            if rankingStore.evaluations.isEmpty {
                emptyView(
                    title: "Aún no tienes evaluaciones",
                    message: "Las evaluaciones que realices aparecerán aquí."
                )
            } else {
                ForEach(rankingStore.evaluations) { evaluation in
                    MyVoteRow(evaluation: evaluation)
                }
            }
        }
    }

    // MARK: - Footer

    private var footerInfo: some View {
        VStack(alignment: .leading, spacing: 10) {

            Divider()

            Label(
                "Ranking provisional",
                systemImage: "chart.bar"
            )
            .font(.headline)

            Text(
                "Esta información es provisional y puede cambiar mientras los jurados continúan registrando sus evaluaciones."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button {
                // Pendiente de conectar con actas
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal")
                    Text("Verificar Actas Emitidas")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionTitle(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func notice(
        icon: String,
        text: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.appPrimary)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            Color.appPrimary.opacity(0.08)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func emptyView(
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)

            Text("No se pudo cargar el ranking")
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Ranking Row

private struct RankingProjectRow: View {
    let position: Int
    let project: ProjectCard

    var body: some View {
        HStack(spacing: 12) {

            Text("\(position)")
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(Color.appPrimary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {

                Text(project.name)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let stand = project.standCode {
                        Label(
                            stand,
                            systemImage: "mappin"
                        )
                    }

                    if let category = project.categoryName {
                        Label(
                            category,
                            systemImage: "square.grid.2x2"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("—")
                    .font(.headline)

                Text("/ 20")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Criterion

private struct CriterionRow: View {
    let criterion: Criterion

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {

            HStack {
                Text(criterion.name)
                    .font(.subheadline.bold())

                Spacer()

                Text(
                    "\(criterion.minScore.formatted()) – \(criterion.maxScore.formatted())"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let description = criterion.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - My Vote

private struct MyVoteRow: View {
    let evaluation: Evaluation

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    evaluation.project?.name ?? "Proyecto"
                )
                .font(.subheadline.bold())

                if let comment = evaluation.comment,
                   !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(
                    evaluation.totalScore.formatted(
                        .number.precision(
                            .fractionLength(0...1)
                        )
                    )
                )
                .font(.headline)

                Text("/ 20")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
