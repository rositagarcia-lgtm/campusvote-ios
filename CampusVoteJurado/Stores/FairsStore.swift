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
    private var loadID = UUID()

    init(api: APIClient) {
        self.api = api
    }

    var allFairs: [FairAssignment] {
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
        let requestID = UUID()
        loadID = requestID
        isLoading = true
        errorMessage = nil
        defer {
            if loadID == requestID { isLoading = false }
        }

        do {
            let assignments = try await api.allAssignments()
            try Task.checkCancellation()
            guard loadID == requestID else { return }
            activeFairs = assignments.filter { $0.access.phase == .live }
            closedFairs = assignments.filter { $0.access.phase == .ended }
            scheduledFairs = assignments.filter {
                let phase = $0.access.phase
                return phase != .live && phase != .ended
            }
        } catch is CancellationError {
            return
        } catch {
            guard loadID == requestID else { return }
            errorMessage = error.userMessage
        }
    }

    func reset() {
        activeFairs = []
        scheduledFairs = []
        closedFairs = []
        isLoading = false
        errorMessage = nil
        loadID = UUID()
    }
}
