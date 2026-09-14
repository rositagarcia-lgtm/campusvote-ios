import SwiftUI

/// Pantalla 06 · Calificar con la rúbrica: una nota por criterio, dentro de su rango.
/// Si el jurado ya lo había evaluado, parte de sus notas y al guardar las corrige.
struct EvaluateView: View {
    let route: EvaluateRoute
    @Environment(EvaluationStore.self) private var evaluation
    @Environment(\.dismiss) private var dismiss
    @State private var scores: [String: Double] = [:]
    @State private var comment = ""

    var body: some View {
        Form {
            if let rubric = evaluation.rubric {
                Section(rubric.name) {
                    ForEach(rubric.orderedCriteria) { criterion in
                        CriterionScoreRow(criterion: criterion, score: binding(for: criterion))
                    }
                }
                Section("Total") {
                    Text(total(for: rubric), format: .number)
                        .font(.title.bold())
                }
            } else {
                ProgressView()
            }

            Section("Comentario (opcional)") {
                TextField("Qué destacas del proyecto", text: $comment, axis: .vertical)
                    .lineLimit(3...6)
            }

            if let message = evaluation.errorMessage {
                Section {
                    ErrorBanner(message: message)
                }
            }
        }
        .navigationTitle(route.projectName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task {
                        let saved = await evaluation.save(
                            fairId: route.fair.id,
                            projectId: route.projectId,
                            scores: scores,
                            comment: comment
                        )
                        if saved {
                            dismiss()
                        }
                    }
                }
                .disabled(evaluation.isSaving || evaluation.rubric == nil)
            }
        }
        .onAppear(perform: loadPrevious)
    }

    private func binding(for criterion: Criterion) -> Binding<Double> {
        Binding(
            get: { scores[criterion.id] ?? criterion.minScore },
            set: { scores[criterion.id] = $0 }
        )
    }

    private func total(for rubric: Rubric) -> Double {
        rubric.criteria.reduce(0) { suma, criterion in
            suma + (scores[criterion.id] ?? criterion.minScore)
        }
    }

    /// Si ya había una evaluación, carga sus notas y su comentario.
    private func loadPrevious() {
        guard scores.isEmpty, let previous = evaluation.evaluation(for: route.projectId) else { return }
        for detail in previous.details {
            scores[detail.criterionId] = detail.score
        }
        comment = previous.comment ?? ""
    }
}

/// Una nota entre min_score y max_score del criterio, de un punto en un punto.
private struct CriterionScoreRow: View {
    let criterion: Criterion
    @Binding var score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(criterion.name)
                    .font(.headline)
                Spacer()
                Text(score, format: .number)
                    .font(.headline.monospacedDigit())
            }
            Slider(value: $score, in: criterion.minScore...criterion.maxScore, step: 1)
            if let description = criterion.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
