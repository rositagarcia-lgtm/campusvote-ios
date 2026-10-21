import Foundation
import Observation

/// Proyectos de GET /fairs/{fairId}/review-projects y la reseña de cada uno.
@Observable
@MainActor
final class ProjectsStore {
    private(set) var projects: [ReviewProject] = []
    private(set) var summary = ReviewSummary(rated: 0, total: 0)
    private(set) var categories: [Category] = []
    private(set) var isLoading = false
    var errorMessage: String?
    private(set) var fairId: String?

    private(set) var assignedProjects: [ReviewProject] = []
    private(set) var assignedSummary = ReviewSummary(rated: 0, total: 0)
    private(set) var isLoadingAssigned = false
    var assignedErrorMessage: String?
    private(set) var assignedLoaded = false

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    var pending: [ReviewProject] {
        projects.filter(\.sinResena)
    }

    var rated: [ReviewProject] {
        projects.filter { !$0.sinResena }
    }

    func load(fairId: String) async {
        if fairId != self.fairId {
            projects = []
            summary = ReviewSummary(rated: 0, total: 0)
            categories = []
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let list = try await api.send(
                .reviewProjects(fairId: fairId),
                as: ReviewList.self
            )
            self.fairId = fairId
            projects = list.projects
            summary = list.summary
            categories = uniqueCategories(in: list.projects)
        } catch {
            errorMessage = error.userMessage
        }
    }

    /// Proyectos asignados al jurado en todas sus ferias abiertas.
    /// GET /fairs/my-projects ya filtra por sus categorías asignadas.
    func loadAssigned() async {
        isLoadingAssigned = true
        assignedErrorMessage = nil
        defer { isLoadingAssigned = false }

        do {
            let list = try await api.send(.myProjects, as: ReviewList.self)
            assignedProjects = list.projects
            assignedSummary = list.summary
            assignedLoaded = true
        } catch {
            assignedErrorMessage = error.userMessage
        }
    }

    func isAssigned(projectId: String) -> Bool {
        assignedProjects.contains { $0.id == projectId }
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

    func saveRating(
        fairId: String,
        projectId: String,
        rating: Int,
        comment: String
    ) async -> ProjectRating? {
        guard (1...5).contains(rating) else {
            errorMessage = "La reseña va de 1 a 5 estrellas."
            return nil
        }

        let text = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 10, text.count <= 1000 else {
            errorMessage = "El comentario debe tener entre 10 y 1000 caracteres."
            return nil
        }

        errorMessage = nil
        do {
            let saved = try await api.send(
                .saveRating(
                    fairId: fairId,
                    projectId: projectId,
                    body: ReviewPutBody(rating: rating, comment: text)
                ),
                as: ProjectRating.self
            )
            apply(saved, projectId: projectId, fallbackRating: rating, fallbackComment: text)
            return saved
        } catch {
            errorMessage = error.userMessage
            return nil
        }
    }

    private func apply(
        _ saved: ProjectRating,
        projectId: String,
        fallbackRating: Int,
        fallbackComment: String
    ) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index] = rated(
                projects[index],
                rating: saved.rating ?? fallbackRating,
                comment: saved.comment ?? fallbackComment
            )
            summary = ReviewSummary(projects: projects)
        }

        if let index = assignedProjects.firstIndex(where: { $0.id == projectId }) {
            assignedProjects[index] = rated(
                assignedProjects[index],
                rating: saved.rating ?? fallbackRating,
                comment: saved.comment ?? fallbackComment
            )
            assignedSummary = ReviewSummary(projects: assignedProjects)
        }
    }

    private func rated(_ project: ReviewProject, rating: Int, comment: String) -> ReviewProject {
        ReviewProject(
            id: project.id,
            fairId: project.fairId,
            fairName: project.fairName,
            name: project.name,
            coverUrl: project.coverUrl,
            categoryId: project.categoryId,
            categoryName: project.categoryName,
            standCode: project.standCode,
            teamName: project.teamName,
            myRating: rating,
            myComment: comment
        )
    }

    private func uniqueCategories(in projects: [ReviewProject]) -> [Category] {
        var seen = Set<String>()
        return projects.compactMap { project in
            guard let id = project.categoryId,
                  let name = project.categoryName,
                  seen.insert(id).inserted else {
                return nil
            }
            return Category(id: id, fairId: fairId, name: name, description: nil)
        }
    }
}
