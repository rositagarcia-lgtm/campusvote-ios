import Foundation
import Observation

/// Estructura para respuestas HTTP sin contenido útil en el cuerpo.
struct EmptyResponse: Decodable {}

/// Rúbrica de la feria, evaluaciones del jurado y su avance.
@Observable
@MainActor
final class EvaluationStore {
    private(set) var rubric: Rubric?
    private(set) var progress: JuryProgress?
    private(set) var evaluations: [Evaluation] = []
    private(set) var isSaving = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    private(set) var categoryRubrics: [CategoryRubricSummary] = []

    func load(fairId: String) async {
        errorMessage = nil
        rubric = nil
        evaluations = []
        await refreshProgress(fairId: fairId)
    }

    func refreshProgress(fairId: String) async {
        do {
            progress = try await api.send(.myProgress(fairId: fairId), as: JuryProgress.self)
        } catch {
            errorMessage = error.userMessage
        }
        do {
            categoryRubrics = try await api.send(.myRubrics(fairId: fairId), as: MyRubricsPayload.self).groups
        } catch {
            errorMessage = error.userMessage
        }
    }

    /// La evaluación que este jurado ya hizo del proyecto, si existe.
    func evaluation(for projectId: String) -> Evaluation? {
        evaluations.first { $0.resolvedProjectId == projectId }
    }

}
