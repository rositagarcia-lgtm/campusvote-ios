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

        categories = uniqueCategories(in: projects)
        rubric = nil
        evaluations = []
    }

    private func uniqueCategories(in projects: [Project]) -> [Category] {
        var seen = Set<String>()
        return projects.compactMap { project in
            guard let id = project.categoryId, let name = project.categoryName, seen.insert(id).inserted else {
                return nil
            }
            return Category(id: id, fairId: project.fairId, name: name, description: nil)
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
