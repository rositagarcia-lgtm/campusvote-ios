import Foundation
import Observation

/// Proyectos aprobados de la feria abierta, con búsqueda y filtros.
@Observable
@MainActor
final class ProjectsStore {
    private(set) var projects: [ProjectCard] = []
    private(set) var searchResults: [ProjectSearchResult] = []
    private(set) var categories: [Category] = []
    private(set) var stands: [Stand] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // Filtros de la lista. Las vistas los enlazan con @Bindable.
    var search = ""
    var categoryId: String?
    var standId: String?

    // Estado del buscador (modo observador).
    var searchText = ""
    var searchCategoryId: String?
    var searchStandId: String?

    private var currentFairId: String?
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    /// Cambia cuando cambia algún filtro; la lista lo usa para recargar.
    var filterKey: String {
        "\(search)|\(categoryId ?? "")|\(standId ?? "")"
    }

    /// Al entrar a otra feria se limpian los filtros y se cargan sus categorías y stands.
    /// Si la carga falla, se puede volver a intentar.
    func open(fairId: String) async {
        guard fairId != currentFairId || categories.isEmpty else { return }
        let cambiandoFeria = fairId != currentFairId
        if cambiandoFeria {
            projects = []
            search = ""
            categoryId = nil
            standId = nil
            clearSearch()
        }
        do {
            let loaded = try await api.send(.projects(fairId: fairId), as: [ProjectCard].self)
            projects = loaded
            categories = uniqueCategories(in: loaded)
            stands = uniqueStands(in: loaded)
            currentFairId = fairId
        } catch {
            errorMessage = error.userMessage
        }
    }

    private func uniqueCategories(in projects: [Project]) -> [Category] {
        var seen = Set<String>()
        return projects.compactMap { project in
            guard let id = project.categoryId, let name = project.categoryName, seen.insert(id).inserted else {
                return nil
            }
            return Category(id: id, fairId: project.fairId, name: name, description: nil)
        }
    }

    private func uniqueStands(in projects: [Project]) -> [Stand] {
        var seen = Set<String>()
        return projects.compactMap { project in
            guard let id = project.standId, let code = project.standCode, seen.insert(id).inserted else {
                return nil
            }
            return Stand(id: id, fairId: project.fairId, code: code, description: nil)
        }
    }

    func load(fairId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let text = search.trimmingCharacters(in: .whitespaces)
        do {
            projects = try await api.send(
                .projects(
                    fairId: fairId,
                    search: text.isEmpty ? nil : text,
                    categoryId: categoryId,
                    standId: standId
                ),
                as: [ProjectCard].self
            )
        } catch {
            errorMessage = error.userMessage
        }
    }

    func detail(fairId: String, projectId: String) async -> ProjectDetail? {
        do {
            return try await api.send(.projectDetail(fairId: fairId, projectId: projectId), as: ProjectDetail.self)
        } catch {
            errorMessage = error.userMessage
            return nil
        }
    }

    /// Clave que cambia con cada filtro del buscador; la vista la usa como
    /// `.task(id:)` para relanzar la búsqueda y recargar los resultados.
    var searchRevision: String {
        "\(searchText)|\(searchCategoryId ?? "")|\(searchStandId ?? "")"
    }

    /// Busca proyectos (modo observador) y actualiza `searchResults`.
    func searchProjects(fairId: String) async {
        let text = searchText.trimmingCharacters(in: .whitespaces)

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let found = try await api.send(
                .projects(
                    fairId: fairId,
                    search: text.isEmpty ? nil : text,
                    categoryId: searchCategoryId,
                    standId: searchStandId
                ),
                as: [Project].self
            )
            searchResults = found.map(ProjectSearchResult.init(project:))
        } catch {
            searchResults = []
            errorMessage = error.userMessage
        }
    }

    /// Deja el buscador en blanco (texto y filtros).
    func clearSearch() {
        searchText = ""
        searchCategoryId = nil
        searchStandId = nil
    }
}
