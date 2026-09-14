import Foundation
import Observation

@Observable
@MainActor
final class FairsStore {
    private(set) var activeFairs: [FairAssignment] = []
    private(set) var closedFairs: [FairAssignment] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func fetchMyAssignments() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let assignments = try await api.send(.myAssignments, as: [FairAssignment].self)
            self.activeFairs = assignments.filter { $0.fair.status.uppercased() != "CLOSED" }
            self.closedFairs = assignments.filter { $0.fair.status.uppercased() == "CLOSED" }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
