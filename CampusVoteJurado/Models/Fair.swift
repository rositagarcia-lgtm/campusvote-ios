import Foundation

/// Feria asignada al jurado.
struct Fair: Decodable, Hashable, Identifiable {
    let id: String
    let name: String
    let description: String?
    /// DRAFT (en preparación) · OPEN (abierta) · CLOSED (cerrada)
    let status: String
    let startsAt: Date?
    let endsAt: Date?

    var isOpen: Bool {
        status == "OPEN"
    }

    /// El jurado solo puede evaluar desde que empieza la feria.
    var hasStarted: Bool {
        guard let startsAt else { return true }
        return startsAt <= .now
    }

    var statusLabel: String {
        switch status {
        case "OPEN":
            if hasStarted { return "En curso" }
            let inicio = startsAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
            return "Empieza el \(inicio)"
        case "CLOSED":
            return "Cerrada"
        default:
            return "En preparación"
        }
    }
}

/// Elemento de GET /fairs/my-assignments.
struct Assignment: Decodable, Hashable {
    let assignedAt: Date
    let fair: Fair
}
