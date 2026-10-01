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
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let current = projects[index]
        projects[index] = ReviewProject(
            id: current.id,
            name: current.name,
            coverUrl: current.coverUrl,
            categoryId: current.categoryId,
            categoryName: current.categoryName,
            myRating: saved.rating ?? fallbackRating,
            myComment: saved.comment ?? fallbackComment
        )
        summary = ReviewSummary(projects: projects)
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
