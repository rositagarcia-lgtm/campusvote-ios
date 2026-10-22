import Foundation
import Observation

/// Proyectos de GET /fairs/{fairId}/review-projects y la reseña de cada uno.
@Observable
@MainActor
final class ProjectsStore {
    var projects: [ReviewProject] = []
    var summary = ReviewSummary(rated: 0, total: 0)
    var categories: [Category] = []
    var isLoading = false
    var errorMessage: String?
    var fairId: String?

    var assignedProjects: [ReviewProject] = []
    var assignedSummary = ReviewSummary(rated: 0, total: 0)
    var isLoadingAssigned = false
    var assignedErrorMessage: String?
    var assignedLoaded = false

    let api: APIClient
    private var loadID = UUID()
    private var assignedLoadID = UUID()
    var accessByFair: [String: ReviewAccess] = [:]
    var dataGeneration = UUID()
    private(set) var scope: ReviewScope = .assigned

    func access(fairId: String, fallback: ReviewAccess) -> ReviewAccess {
        if fallback.phase == .ended { return fallback }
        return (accessByFair[fairId] ?? ReviewAccess()).merging(fallback)
    }

    func uniqueCategories(in projects: [ReviewProject]) -> [Category] {
        var seen = Set<String>()
        return projects.compactMap { project in
            guard let id = project.categoryId, let name = project.categoryName,
                  seen.insert(id).inserted else { return nil }
            return Category(id: id, fairId: fairId, name: name, description: nil)
        }
    }

    init(api: APIClient) {
        self.api = api
    }

    var pending: [ReviewProject] {
        projects.filter(\.sinResena)
    }

    var rated: [ReviewProject] {
        projects.filter { !$0.sinResena }
    }

    func load(fairId: String, scope: ReviewScope = .assigned) async {
        let requestID = UUID()
        loadID = requestID
        if fairId != self.fairId || scope != self.scope {
            projects = []
            summary = ReviewSummary(rated: 0, total: 0)
            categories = []
        }

        self.fairId = fairId
        self.scope = scope
        isLoading = true
        errorMessage = nil
        defer {
            if loadID == requestID { isLoading = false }
        }

        do {
            let list = try await api.send(
                .reviewProjects(fairId: fairId, scope: scope),
                as: ReviewList.self
            )
            try Task.checkCancellation()
            guard loadID == requestID else { return }
            self.fairId = fairId
            self.scope = list.scope ?? scope
            accessByFair[fairId] = list.access.merging(accessByFair[fairId] ?? ReviewAccess())
            projects = list.projects
            summary = list.summary
            categories = uniqueCategories(in: list.projects)
        } catch is CancellationError {
            return
        } catch {
            guard loadID == requestID else { return }
            errorMessage = error.userMessage
        }
    }

    /// Proyectos asignados al jurado en todas sus ferias abiertas.
    /// GET /fairs/my-projects ya filtra por sus categorías asignadas.
    func loadAssigned() async {
        let requestID = UUID()
        assignedLoadID = requestID
        isLoadingAssigned = true
        assignedErrorMessage = nil
        defer {
            if assignedLoadID == requestID { isLoadingAssigned = false }
        }

        do {
            let list = try await api.send(.myProjects, as: ReviewList.self)
            try Task.checkCancellation()
            guard assignedLoadID == requestID else { return }
            for project in list.projects {
                if let fairId = project.fairId {
                    accessByFair[fairId] = project.access.merging(accessByFair[fairId] ?? ReviewAccess())
                }
            }
            assignedProjects = list.projects
            assignedSummary = list.summary
            assignedLoaded = true
        } catch is CancellationError {
            return
        } catch {
            guard assignedLoadID == requestID else { return }
            assignedErrorMessage = error.userMessage
        }
    }

    func isAssigned(projectId: String) -> Bool {
        assignedProjects.contains { $0.id == projectId }
    }

    func reset() {
        dataGeneration = UUID()
        projects = []
        summary = ReviewSummary(rated: 0, total: 0)
        categories = []
        fairId = nil
        scope = .assigned
        accessByFair = [:]
        errorMessage = nil
        isLoading = false
        assignedProjects = []
        assignedSummary = ReviewSummary(rated: 0, total: 0)
        assignedErrorMessage = nil
        isLoadingAssigned = false
        assignedLoaded = false
        loadID = UUID()
        assignedLoadID = UUID()
    }

    func assignedProject(id: String) -> ReviewProject? {
        assignedProjects.first { $0.id == id }
    }

    /// Todas es `categoryId == nil`. El texto y el chip no vuelven a llamar al servidor.
    func filtered(search: String, categoryId: String?) -> [ReviewProject] {
        let text = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return projects.filter { project in
            let sameCategory = categoryId == nil || project.categoryId == categoryId
            let matchesText = text.isEmpty
                || project.name.localizedCaseInsensitiveContains(text)
                || (project.categoryName?.localizedCaseInsensitiveContains(text) ?? false)
            return sameCategory && matchesText
        }
    }

    func detail(fairId: String, projectId: String) async -> ProjectDetail? {
        do {
            return try await api.send(
                .projectDetail(fairId: fairId, projectId: projectId),
                as: ProjectDetail.self
            )
        } catch {
            errorMessage = error.userMessage
            return nil
        }
    }

    func rating(fairId: String, projectId: String) async -> ProjectRating? {
        do {
            return try await api.send(
                .projectRating(fairId: fairId, projectId: projectId),
                as: ProjectRating.self
            )
        } catch {
            errorMessage = error.userMessage
            return nil
        }
    }

}
