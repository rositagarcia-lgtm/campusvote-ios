import Foundation

extension APIClient {
    func allAssignments() async throws -> [FairAssignment] {
        var assignments: [FairAssignment] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let result = try await sendPage(.assignments(page: page), as: FairAssignment.self)
            assignments.append(contentsOf: result.items)
            if result.items.isEmpty || page >= result.pagination.totalPages { break }
            page += 1
        }
        var seen = Set<String>()
        return assignments.filter { seen.insert($0.id).inserted }
    }
}
