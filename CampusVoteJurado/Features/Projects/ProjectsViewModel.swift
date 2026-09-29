import SwiftUI
import Observation

/// Estado de la rúbrica de un proyecto, para la tarjeta de la lista.
enum RubricPhase: Sendable {
    case pending
    case draft(checked: Int, total: Int)
    case submitted(score: Double?)
}

struct AssignedProject: Identifiable {
    let project: Project
    let phase: RubricPhase
    var id: String { project.id }
}

@Observable
@MainActor
final class ProjectsViewModel {
    let fairId: String
    private(set) var projects: [AssignedProject] = []
    private(set) var endsAt: Date?
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared

    init(fairId: String) {
        self.fairId = fairId
    }

    var submittedCount: Int {
        projects.filter {
            if case .submitted = $0.phase { return true }
            return false
        }.count
    }

    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loaded = try await api.send(
                Endpoint.projects(fairId: fairId),
                as: [Project].self
            )
            let assigned = try? await api.send(
                Endpoint.assignment(fairId: fairId),
                as: AssignedFair.self
            )
            let groups = (try? await api.send(
                Endpoint.myRubrics(fairId: fairId),
                as: MyRubricsPayload.self
            ).groups) ?? []

            endsAt = Self.parseDate(assigned?.endsAt)
            let totals = Self.criteriaTotals(groups)
            let phases = await rubricPhases(for: loaded, totals: totals)

            projects = loaded
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                .map { project in
                    AssignedProject(
                        project: project,
                        phase: phases[project.id] ?? .pending
                    )
                }
        } catch {
            errorMessage = error.userMessage
        }
    }

    private func rubricPhases(
        for projects: [Project],
        totals: [String: Int]
    ) async -> [String: RubricPhase] {
        let fairId = fairId
        return await withTaskGroup(of: (String, RubricPhase).self) { group in
            for project in projects {
                let total = Self.criteriaTotal(for: project, totals: totals)
                group.addTask {
                    let saved = try? await APIClient.shared.send(
                        .projectRubric(fairId: fairId, projectId: project.id),
                        as: SavedRubric.self
                    )
                    return (project.id, ProjectsViewModel.phase(saved: saved, total: total))
                }
            }
            var map: [String: RubricPhase] = [:]
            for await (id, phase) in group {
                map[id] = phase
            }
            return map
        }
    }

    private static func criteriaTotals(_ groups: [CategoryRubricSummary]) -> [String: Int] {
        var map: [String: Int] = [:]
        for group in groups where group.criteriaCount > 0 {
            map[group.id] = group.criteriaCount
            map[group.categoryName] = group.criteriaCount
        }
        return map
    }

    private static func criteriaTotal(for project: Project, totals: [String: Int]) -> Int {
        if let id = project.categoryId, let value = totals[id], value > 0 { return value }
        if let name = project.categoryName, let value = totals[name], value > 0 { return value }
        return 0
    }

    /// Enviada si ya se finalizó. Borrador si hay marcas guardadas. Si no, pendiente.
    /// No toca la pantalla, así que puede correr en la tarea de cada proyecto.
    nonisolated private static func phase(saved: SavedRubric?, total: Int) -> RubricPhase {
        guard let saved else { return .pending }
        if saved.isSubmitted {
            return .submitted(score: saved.score)
        }
        let checked = saved.responses.filter(\.checked).count
        if checked == 0 && saved.responses.isEmpty {
            return .pending
        }
        let denominator = total > 0 ? total : saved.responses.count
        return .draft(checked: checked, total: denominator)
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: raw)
    }
}
