import Foundation
import Observation

/// Proyectos aprobados de una feria y su ficha pública.
/// GET /projects y GET /public/fairs/{fairId}/projects/{projectId}.
@Observable
@MainActor
final class ProjectsCatalogStore {
    private(set) var projects: [Project] = []
    private(set) var isLoading = false
    var errorMessage: String?
    private(set) var loadedFairId: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load(fairId: String) async {
        if fairId != loadedFairId {
            projects = []
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var collected: [Project] = []
        var page = 1

        do {
            while page <= 50 {
                let result = try await api.sendPage(
                    .allProjects(fairId: fairId, page: page, limit: 100),
                    as: Project.self
                )
                collected.append(contentsOf: result.items)

                let totalPages = max(result.pagination.totalPages, 1)
                if page >= totalPages || result.items.isEmpty {
                    break
                }
                page += 1
            }

            loadedFairId = fairId
            projects = collected
        } catch {
            errorMessage = error.userMessage
        }
    }

    func project(id: String) async -> Project? {
        try? await api.send(.project(id: id), as: Project.self)
    }

    func publicProject(fairId: String, projectId: String) async -> PublicProject? {
        try? await api.send(
            .publicProject(fairId: fairId, projectId: projectId),
            as: PublicProject.self
        )
    }
}
