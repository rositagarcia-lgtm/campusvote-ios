import Foundation
import Observation

@Observable
@MainActor
final class FairsStore {
    private(set) var activeFairs: [FairAssignment] = []
    private(set) var scheduledFairs: [FairAssignment] = []
    private(set) var closedFairs: [FairAssignment] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    private var allFairs: [FairAssignment] {
        activeFairs + scheduledFairs + closedFairs
    }

    var organizationName: String? {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return allFairs.compactMap { $0.fair.organizationName }.first
    }

    var siteName: String? {
        let names = Set(allFairs.compactMap { $0.fair.siteName })
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
            activeFairs = assignments.filter { $0.fair.status.uppercased() == "OPEN" }
            closedFairs = assignments.filter { $0.fair.status.uppercased() == "CLOSED" }
            scheduledFairs = assignments.filter {
                let status = $0.fair.status.uppercased()
                return status != "OPEN" && status != "CLOSED"
            }
        } catch {
            errorMessage = error.userMessage
        }
    }
}
