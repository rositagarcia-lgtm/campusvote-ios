import SwiftUI
import Observation

enum ProjectTab {
    case pending
    case evaluated
}

@Observable
@MainActor
final class ProjectsViewModel {
    let fairId: String
    var fairName: String = "Feria de Proyectos"
    var juryTable: String = "Jurado Calificador"
    var selectedTab: ProjectTab = .pending
    var isLoading: Bool = false
    var errorMessage: String?

    private(set) var pendingProjects: [Project] = []
    private(set) var evaluatedProjects: [Project] = []

    private let api = APIClient.shared

    var remainingCount: Int { pendingProjects.count }
    var evaluatedCount: Int { evaluatedProjects.count }

    init(fairId: String) {
        self.fairId = fairId
    }

    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let progressTask = api.send(
                Endpoint.myProgress(fairId: fairId),
                as: JuryProgress.self
            )
            async let projectsTask = api.send(
                Endpoint.projects(fairId: fairId),
                as: [Project].self
            )
            async let evaluationsTask = api.send(
                Endpoint.myEvaluations(fairId: fairId),
                as: [Evaluation].self
            )

            let (progress, projects, evaluations) = try await (
                progressTask,
                projectsTask,
                evaluationsTask
            )

            if let fairName = progress.fairName, !fairName.isEmpty {
                self.fairName = fairName
            }

            let evaluatedIds = Set(evaluations.compactMap(\.resolvedProjectId))

            // Calificados: los que ya tienen evaluación propia. Si el proyecto no
            // aparece en la lista (p. ej. cambió de estado), se usa el proyectito
            // que trae la evaluación.
            evaluatedProjects = projects
                .filter { evaluatedIds.contains($0.id) }
                + evaluations
                    .compactMap { evaluation -> Project? in
                        guard
                            let nested = evaluation.project,
                            !projects.contains(where: { $0.id == nested.id })
                        else {
                            return nil
                        }
                        return Project(
                            id: nested.id,
                            fairId: fairId,
                            name: nested.name,
                            description: nested.description,
                            status: nested.status
                        )
                    }

            pendingProjects = projects
                .filter { !evaluatedIds.contains($0.id) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            evaluatedProjects = evaluatedProjects
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        } catch {
            errorMessage = error.userMessage
        }
    }
}
