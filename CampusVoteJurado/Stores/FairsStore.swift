import Foundation
import Observation

@Observable
@MainActor
final class FairsStore {
    /// Solo las ferias con estado OPEN. Esas sí se pueden abrir.
    private(set) var activeFairs: [FairAssignment] = []
    /// El resto se ve y no se abre.
    private(set) var closedFairs: [FairAssignment] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    var organizationName: String? {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return (activeFairs + closedFairs).compactMap { $0.fair.organizationName }.first
    }

    var siteName: String? {
        let names = Set((activeFairs + closedFairs).compactMap { $0.fair.siteName })
        guard names.count == 1 else { return nil }
        return names.first
    }

    var hasLiveFair: Bool {
        !activeFairs.isEmpty
    }

    func fetchMyAssignments() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let assignments = try await api.send(.myAssignments, as: [FairAssignment].self)
            activeFairs = assignments.filter { $0.fair.isOpen }
            closedFairs = assignments.filter { !$0.fair.isOpen }
        } catch {
            errorMessage = error.userMessage
        }
    }
}
