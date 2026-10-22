import Foundation

extension ProjectsStore {
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
        guard text.utf16.count >= 10, text.utf16.count <= 1000 else {
            errorMessage = "El comentario debe tener entre 10 y 1000 caracteres."
            return nil
        }

        let generation = dataGeneration
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
            try Task.checkCancellation()
            guard dataGeneration == generation else { return nil }
            apply(saved, projectId: projectId, fallbackRating: rating, fallbackComment: text)
            return saved
        } catch {
            guard dataGeneration == generation else { return nil }
            if (error as? APIError)?.code == "REVIEW_NOT_OPEN_YET" {
                accessByFair[fairId] = ReviewAccess(phase: .preview, canReview: false)
            } else if (error as? APIError)?.code == "REVIEW_CLOSED" {
                accessByFair[fairId] = ReviewAccess(phase: .ended, canReview: false)
            }
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
            myComment: comment,
            access: project.access,
            inMyCategories: project.inMyCategories
        )
    }

}
