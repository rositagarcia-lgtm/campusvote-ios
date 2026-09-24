import Foundation
import Observation

@Observable
@MainActor
final class RankingStore {

    private(set) var projects: [ProjectCard] = []
    private(set) var categories: [Category] = []
    private(set) var evaluations: [Evaluation] = []
    private(set) var rubric: Rubric?

    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load(fairId: String) async {
        isLoading = true
        errorMessage = nil

        projects = []
        categories = []
        evaluations = []
        rubric = nil

        defer {
            isLoading = false
        }

        do {
            projects = try await api.send(
                .projects(
                    fairId: fairId,
                    search: nil,
                    categoryId: nil,
                    standId: nil
                ),
                as: [ProjectCard].self
            )
        } catch {
            errorMessage = "No se pudieron cargar los proyectos: \(error.userMessage ?? "Error desconocido.")"
            return
        }

        do {
            let response = try await api.send(
                .categories(fairId: fairId),
                as: CategoryList.self
            )
            categories = response.categories
        } catch {
            categories = []
        }

        do {
            rubric = try await api.send(
                .rubric(fairId: fairId),
                as: Rubric.self
            )
        } catch {
            rubric = nil
        }

        do {
            evaluations = try await api.send(
                .myEvaluations(fairId: fairId),
                as: [Evaluation].self
            )
        } catch {
            evaluations = []
        }
    }

    func evaluation(for projectId: String) -> Evaluation? {
        evaluations.first { $0.resolvedProjectId == projectId }
    }

    func categoryName(for project: ProjectCard) -> String {
        project.categoryName ?? "Sin categoría"
    }

    func standName(for project: ProjectCard) -> String {
        project.standCode ?? "Sin stand"
    }
}
