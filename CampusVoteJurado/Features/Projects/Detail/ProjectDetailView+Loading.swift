import SwiftUI

extension ProjectDetailView {
    func heroURL(_ detail: ProjectDetail) -> String? {
        if let cover = detail.coverUrl, !cover.isEmpty, cover != detail.logoUrl {
            return cover
        }
        return detail.imageUrls.first { $0 != detail.logoUrl && !$0.isEmpty }
    }

    func gallery(_ detail: ProjectDetail) -> [String] {
        var urls: [String] = []
        if let hero = heroURL(detail) {
            urls.append(hero)
        }
        for url in detail.imageUrls where url != detail.logoUrl && !url.isEmpty && !urls.contains(url) {
            urls.append(url)
        }
        return urls
    }

    func loadHighlights() {
        let saved = UserDefaults.standard.stringArray(forKey: highlightsKey) ?? []
        aspects = Set(saved.filter { aspectos.contains($0) })
    }

    func refreshReviewAccess() async {
        let generation = store.dataGeneration
        do {
            let assignment = try await api.send(.assignment(fairId: fairId), as: FairAssignment.self)
            try Task.checkCancellation()
            guard store.dataGeneration == generation else { return }
            loadedAccess = assignment.access
            store.accessByFair[fairId] = assignment.access
            if reviewAccess.allowsReview && !ratingLoaded { await load() }
        } catch {
            guard store.dataGeneration == generation else { return }
            errorMessage = error.userMessage
        }
    }

    func load() async {
        let requestID = UUID()
        detailLoadID = requestID
        let generation = store.dataGeneration
        isLoading = true
        ratingLoaded = false
        detail = nil
        errorMessage = nil
        defer { if detailLoadID == requestID { isLoading = false } }

        do {
            let assignment = try await api.send(.assignment(fairId: fairId), as: FairAssignment.self)
            try Task.checkCancellation()
            guard detailLoadID == requestID, store.dataGeneration == generation else { return }
            loadedAccess = assignment.access
            store.accessByFair[fairId] = assignment.access
            guard reviewAccess.allowsBrowsing else { return }
            let loadedDetail = try await api.send(
                .projectDetail(fairId: fairId, projectId: projectId),
                as: ProjectDetail.self
            )
            try Task.checkCancellation()
            guard detailLoadID == requestID, store.dataGeneration == generation else { return }
            detail = loadedDetail
        } catch {
            guard detailLoadID == requestID, store.dataGeneration == generation else { return }
            errorMessage = error.userMessage
            return
        }

        guard reviewAccess.allowsReview else { return }
        do {
            let loaded = try await api.send(
                .projectRating(fairId: fairId, projectId: projectId),
                as: ProjectRating.self
            )
            try Task.checkCancellation()
            guard detailLoadID == requestID, store.dataGeneration == generation else { return }
            stars = min(max(loaded.rating ?? 0, 0), 5)
            comment = String((loaded.comment ?? "").prefix(1000))
            ratingLoaded = true
        } catch let error as APIError {
            guard detailLoadID == requestID, store.dataGeneration == generation else { return }
            if error.code == "REVIEW_NOT_OPEN_YET" {
                store.accessByFair[fairId] = ReviewAccess(phase: .preview, canReview: false)
            } else if error.code == "REVIEW_CLOSED" {
                store.accessByFair[fairId] = ReviewAccess(phase: .ended, canReview: false)
            }
            errorMessage = error.message
        } catch {
            guard detailLoadID == requestID, store.dataGeneration == generation else { return }
            if errorMessage == nil {
                errorMessage = error.userMessage
            }
        }
    }

    func save() async {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        if let saved = await store.saveRating(
            fairId: fairId,
            projectId: projectId,
            rating: stars,
            comment: comment
        ) {
            stars = min(max(saved.rating ?? stars, 0), 5)
            comment = String((saved.comment ?? comment).prefix(1000))
            saveAlert = SaveAlert(
                title: "Reseña guardada",
                message: "Tu reseña y comentario se guardaron correctamente."
            )
        } else {
            errorMessage = store.errorMessage
        }
    }
}
