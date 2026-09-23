import Foundation
import Observation

/// Estructura para respuestas HTTP sin contenido en el cuerpo.
struct EmptyResponse: Decodable {}

/// Rúbrica de la feria, evaluaciones del jurado y su avance.
@Observable
@MainActor
final class EvaluationStore {
    private(set) var rubric: Rubric?
    private(set) var progress: JuryProgress?
    private(set) var isSaving = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load(fairId: String) async {
        do {
            rubric = try await api.send(.rubric(fairId: fairId), as: Rubric.self)
            progress = try await api.send(.myProgress(fairId: fairId), as: JuryProgress.self)
        } catch {
            errorMessage = error.userMessage
        }
    }

    func refreshProgress(fairId: String) async {
        do {
            progress = try await api.send(.myProgress(fairId: fairId), as: JuryProgress.self)
        } catch {
            errorMessage = error.userMessage
        }
    }

    /// La evaluación que este jurado ya hizo del proyecto, si existe.
    func evaluation(for projectId: String) -> Evaluation? {
        progress?.evaluations?.first { $0.projectId == projectId }
    }

    /// Crea la evaluación o, si ya existía, la corrige. Devuelve true si se guardó.
    /// El backend exige una nota por cada criterio de la rúbrica.
    func save(fairId: String, projectId: String, scores: [String: Double], comment: String) async -> Bool {
        guard let rubric else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let text = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        let input = EvaluationInput(
            projectId: projectId,
            comment: text.isEmpty ? nil : text,
            scores: rubric.criteria.map { criterion in
                ScoreInput(criterionId: criterion.id, score: scores[criterion.id] ?? criterion.minScore)
            }
        )

        do {
            if let existing = evaluation(for: projectId) {
                _ = try await api.send(
                    .updateEvaluation(fairId: fairId, evaluationId: existing.id, input: input),
                    as: EmptyResponse.self
                )
            } else {
                _ = try await api.send(
                    .createEvaluation(fairId: fairId, input: input),
                    as: EmptyResponse.self
                )
            }
            progress = try await api.send(.myProgress(fairId: fairId), as: JuryProgress.self)
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}
