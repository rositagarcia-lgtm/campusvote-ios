import SwiftUI

/// Rúbrica de calificación de un proyecto (crear o actualizar la evaluación).
struct EvaluateView: View {
    let fairId: String
    let project: Project
    let onSaved: () -> Void

    @State private var rubric: Rubric?
    @State private var evaluationId: String?
    @State private var scores: [String: Double] = [:]
    @State private var comment = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedMessage: String?

    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared
    private let tealDark = Color(red: 0.03, green: 0.32, blue: 0.28)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Encabezado del proyecto
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                        .font(.title2).bold()
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let stand = project.tableNumber {
                            Label(stand, systemImage: "shippingbox.fill")
                                .font(.caption).bold()
                        }
                        if let category = project.category {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(tealDark.opacity(0.1))
                                .foregroundColor(tealDark)
                                .cornerRadius(6)
                        }
                    }
                    .foregroundColor(.secondary)

                    NavigationLink(destination: ProjectDetailView(fairId: fairId, projectId: project.id)) {
                        Label("Ver detalle del proyecto", systemImage: "doc.text.magnifyingglass")
                            .font(.caption).bold()
                            .foregroundColor(tealDark)
                    }
                }

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }

                if let savedMessage {
                    Label(savedMessage, systemImage: "checkmark.seal.fill")
                        .font(.subheadline).bold()
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isLoading {
                    ProgressView("Cargando rúbrica...")
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else if let rubric {
                    criteriaSection(rubric)
                } else {
                    Text("No hay rúbrica configurada para esta feria todavía.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Rúbrica")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            saveBar
        }
        .task {
            await load()
        }
    }

    // MARK: - Criterios

    @ViewBuilder
    private func criteriaSection(_ rubric: Rubric) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(rubric.name.uppercased())
                    .font(.caption).bold()
                    .foregroundColor(.secondary)
                Spacer()
                Text("Total: \(totalScore.formatted(.number.precision(.fractionLength(0...1))))")
                    .font(.subheadline).bold()
                    .foregroundColor(tealDark)
            }

            ForEach(rubric.orderedCriteria) { criterion in
                criterionCard(criterion)
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(tealDark)
                    .frame(width: 32, height: 32)
                    .background(tealDark.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("COMENTARIO DEL JURADO")
                        .font(.caption).bold()
                        .foregroundColor(.secondary)

                    TextEditor(text: $comment)
                        .font(.subheadline)
                        .frame(minHeight: 90)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground).opacity(0.6))
            .cornerRadius(12)
        }
    }

    private func criterionCard(_ criterion: Criterion) -> some View {
        let value = scores[criterion.id] ?? criterion.minScore

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(criterion.position). \(criterion.name)")
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
                Spacer()
                Text(value.formatted(.number.precision(.fractionLength(0...1))))
                    .font(.headline.monospacedDigit())
                    .foregroundColor(tealDark)
            }

            if let description = criterion.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(
                value: Binding(
                    get: { scores[criterion.id] ?? min(criterion.minScore, criterion.maxScore) },
                    set: { scores[criterion.id] = $0 }
                ),
                in: min(criterion.minScore, criterion.maxScore)...max(criterion.minScore, criterion.maxScore),
                step: 0.5
            )
            .tint(tealDark)

            HStack {
                Text("\(criterion.minScore.formatted(.number))")
                Spacer()
                Text("\(criterion.maxScore.formatted(.number))")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Guardar

    private var canSave: Bool {
        !isSaving && scores.keys.count >= (rubric?.criteria.count ?? 1)
    }

    private var saveBar: some View {
        Button(action: save) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                    Text(evaluationId == nil ? "Registrar evaluación" : "Actualizar evaluación")
                        .font(.subheadline).bold()
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tealDark)
            .cornerRadius(12)
        }
        .disabled(!canSave || rubric == nil)
        .opacity(canSave && rubric != nil ? 1 : 0.5)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Color(.systemBackground))
    }

    private var totalScore: Double {
        guard let rubric else { return 0 }
        return rubric.orderedCriteria.reduce(0) { $0 + (scores[$1.id] ?? $1.minScore) }
    }

    // MARK: - Carga y envío

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedRubric = try await api.send(Endpoint.rubric(fairId: fairId), as: Rubric.self)
            rubric = loadedRubric
            for criterion in loadedRubric.orderedCriteria {
                if scores[criterion.id] == nil {
                    scores[criterion.id] = criterion.minScore
                }
            }

            // Si ya la evaluamos, precargamos los valores para poder editarla.
            let evaluations = try await api.send(
                Endpoint.myEvaluations(fairId: fairId),
                as: [Evaluation].self
            )
            if let existing = evaluations.first(where: { $0.resolvedProjectId == project.id }) {
                evaluationId = existing.id
                comment = existing.comment ?? ""
                for detail in existing.details ?? [] {
                    if let criterionId = detail.criterionId {
                        scores[criterionId] = detail.score
                    }
                }
            }
        } catch {
            errorMessage = error.userMessage
        }
    }

    @MainActor
    private func save() {
        guard let rubric else { return }

        let input = EvaluationInput(
            projectId: project.id,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : comment.trimmingCharacters(in: .whitespacesAndNewlines),
            scores: rubric.orderedCriteria.map {
                ScoreInput(criterionId: $0.id, score: scores[$0.id] ?? $0.minScore)
            }
        )

        isSaving = true
        errorMessage = nil
        savedMessage = nil

        Task {
            do {
                if let evaluationId {
                    _ = try await api.send(
                        Endpoint.updateEvaluation(fairId: fairId, evaluationId: evaluationId, input: input),
                        as: EmptyResponse.self
                    )
                } else {
                    _ = try await api.send(
                        Endpoint.createEvaluation(fairId: fairId, input: input),
                        as: EmptyResponse.self
                    )
                }
                if let evaluations = try? await api.send(
                    Endpoint.myEvaluations(fairId: fairId),
                    as: [Evaluation].self
                ),
                   let existing = evaluations.first(where: { $0.resolvedProjectId == project.id }) {
                    evaluationId = existing.id
                }
                isSaving = false
                savedMessage = "Evaluación guardada correctamente."
                onSaved()
            } catch {
                isSaving = false
                errorMessage = error.userMessage
            }
        }
    }
}
