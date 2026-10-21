import Foundation
import Observation

/// Estado de la pantalla de proyectos: búsqueda y chip. Los datos viven en ProjectsStore.
@Observable
@MainActor
final class ProjectsViewModel {
    let fairId: String
    var search = ""
    /// nil es el chip Todas.
    var categoryId: String?

    private let store: ProjectsStore

    init(fairId: String, store: ProjectsStore) {
        self.fairId = fairId
        self.store = store
    }

    var summary: ReviewSummary { store.summary }
    var categories: [Category] { store.categories }
    var isLoading: Bool { store.isLoading }
    var errorMessage: String? { store.errorMessage }

    var projects: [ReviewProject] {
        store.filtered(search: search, categoryId: categoryId)
    }

    var ratedCount: Int { store.summary.rated }
    var totalCount: Int { store.summary.total }

    func load() async {
        await store.load(fairId: fairId)
    }
}
