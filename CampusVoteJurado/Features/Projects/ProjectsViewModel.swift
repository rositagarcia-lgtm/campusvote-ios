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
            async let projectsTask = api.send(
                Endpoint.projects(fairId: fairId),
                as: [Project].self
            )
            async let assignmentTask = api.send(
                Endpoint.assignment(fairId: fairId),
                as: AssignedFair.self
            )

            let projects = try await projectsTask
            if let assigned = try? await assignmentTask {
                fairName = assigned.name
                if !assigned.heading.isEmpty {
                    juryTable = assigned.heading
                }
            }

            let submitted = await submittedProjectIds(in: projects)
            evaluatedProjects = projects
                .filter { submitted.contains($0.id) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            pendingProjects = projects
                .filter { !submitted.contains($0.id) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = error.userMessage
        }
    }

    private func submittedProjectIds(in projects: [Project]) async -> Set<String> {
        let fairId = fairId
        return await withTaskGroup(of: String?.self) { group in
            for project in projects {
                group.addTask {
                    guard let saved = try? await APIClient.shared.send(
                        .projectRubric(fairId: fairId, projectId: project.id),
                        as: SavedRubric.self
                    ), saved.isSubmitted else {
                        return nil
                    }
                    return project.id
                }
            }
            var ids = Set<String>()
            for await id in group {
                if let id { ids.insert(id) }
            }
            return ids
        }
    }
}
