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

    // MARK: - Cargar información

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

        // --------------------------------------------------
        // 1. PROYECTOS
        // --------------------------------------------------

        do {

            let loadedProjects = try await api.send(
                .projects(
                    fairId: fairId,
                    search: nil,
                    categoryId: nil,
                    standId: nil
                ),
                as: [ProjectCard].self
            )

            projects = loadedProjects

        } catch {

            errorMessage =
                "No se pudieron cargar los proyectos: \(error.userMessage)"

            return
        }

        // --------------------------------------------------
        // 2. CATEGORÍAS
        // --------------------------------------------------

        do {

            let response = try await api.send(
                .categories(
                    fairId: fairId
                ),
                as: CategoryList.self
            )

            categories = response.categories

        } catch {

            // Las categorías no deben impedir
            // mostrar el ranking.

            categories = []
        }

        // --------------------------------------------------
        // 3. RÚBRICA
        // --------------------------------------------------

        do {

            let loadedRubric = try await api.send(
                .rubric(
                    fairId: fairId
                ),
                as: Rubric.self
            )

            rubric = loadedRubric

        } catch {

            // La pantalla puede funcionar
            // aunque no se cargue la rúbrica.

            rubric = nil
        }

        // --------------------------------------------------
        // 4. MIS EVALUACIONES
        // --------------------------------------------------

        do {

            let loadedEvaluations = try await api.send(
                .myEvaluations(
                    fairId: fairId
                ),
                as: [Evaluation].self
            )

            evaluations = loadedEvaluations

        } catch {

            // No bloqueamos el ranking si
            // mis evaluaciones no están disponibles.

            evaluations = []
        }
    }

    // MARK: - Buscar evaluación

    func evaluation(
        for projectId: String
    ) -> Evaluation? {

        evaluations.first {
            $0.projectId == projectId
        }
    }

    // MARK: - Nombre de categoría

    func categoryName(
        for project: ProjectCard
    ) -> String {

        project.categoryName ?? "Sin categoría"
    }

    // MARK: - Nombre del stand

    func standName(
        for project: ProjectCard
    ) -> String {

        project.standCode ?? "Sin stand"
    }
}
