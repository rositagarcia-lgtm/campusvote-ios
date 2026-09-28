import Foundation
import Observation

struct EmptyResponse: Decodable {}

@Observable
@MainActor
final class EvaluationStore {
    private(set) var rubric: Rubric?
    private(set) var progress: JuryProgress?
    private(set) var evaluations: [Evaluation] = []
    private(set) var categoryRubrics: [CategoryRubricSummary] = []
    private(set) var isSaving = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

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

    func evaluation(for projectId: String) -> Evaluation? {
        evaluations.first { $0.resolvedProjectId == projectId }
    }
}
