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
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

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
        if let refreshTask {
            await refreshTask.value
            return
        }

        let requestID = UUID()
        loadID = requestID
        isLoading = true
        errorMessage = nil
        let task = Task { await loadAssignments(requestID: requestID) }
        refreshTask = task
        await task.value
    }

    private func loadAssignments(requestID: UUID) async {
        defer {
            if loadID == requestID {
                isLoading = false
                refreshTask = nil
            }
        }

        do {
            let assignments = try await api.allAssignments()
            try Task.checkCancellation()
            guard loadID == requestID else { return }
            activeFairs = assignments.filter { $0.access.phase == .live || $0.fair.isOpen }
            closedFairs = assignments.filter { $0.access.phase == .ended && !$0.fair.isOpen }
            scheduledFairs = assignments.filter { assignment in
                !activeFairs.contains { $0.id == assignment.id }
                    && !closedFairs.contains { $0.id == assignment.id }
            }
        } catch is CancellationError {
            return
        } catch {
            guard loadID == requestID else { return }
            errorMessage = error.userMessage
        }
    }

    func reset() {
        refreshTask?.cancel()
        refreshTask = nil
        loadID = UUID()
        activeFairs = []
        scheduledFairs = []
        closedFairs = []
        isLoading = false
        errorMessage = nil
    }
}
