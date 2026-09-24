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
    var minScore: Double?
    var maxScore: Double?
    var sortBy: SearchSort = .name

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
            categories = try await api.send(.categories(fairId: fairId), as: CategoryList.self).categories
            stands = try await api.send(.stands(fairId: fairId), as: StandList.self).stands
            currentFairId = fairId
        } catch {
            errorMessage = error.userMessage
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
        let min = minScore.map { String($0) } ?? ""
        let max = maxScore.map { String($0) } ?? ""
        return "\(searchText)|\(searchCategoryId ?? "")|\(min)|\(max)|\(sortBy.rawValue)"
    }

    /// Busca proyectos (modo observador) y actualiza `searchResults`.
    func searchProjects(fairId: String) async {
        let text = searchText.trimmingCharacters(in: .whitespaces)

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            searchResults = try await api.send(
                .searchProjects(
                    fairId: fairId,
                    search: text.isEmpty ? nil : text,
                    categoryId: searchCategoryId,
                    minScore: minScore,
                    maxScore: maxScore,
                    sort: sortBy.rawValue
                ),
                as: [ProjectSearchResult].self
            )
        } catch {
            searchResults = []
            errorMessage = error.userMessage
        }
    }

    /// Deja el buscador en blanco (texto y filtros).
    func clearSearch() {
        searchText = ""
        searchCategoryId = nil
        minScore = nil
        maxScore = nil
        sortBy = .name
    }
}
