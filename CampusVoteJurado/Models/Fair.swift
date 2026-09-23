import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T
}

struct FairAssignment: Codable, Identifiable, Hashable {
    var id: String { fair.id }
    let assignedAt: String?
    let fair: Fair

    enum CodingKeys: String, CodingKey {
        case fair
        case assignedAt = "assigned_at"
    }

    static func == (lhs: FairAssignment, rhs: FairAssignment) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Institución dueña de la feria (la cabecera muestra su nombre).
struct FairOrganization: Codable, Hashable {
    let id: String
    let name: String
}

/// Sede donde se realiza la feria.
struct FairSite: Codable, Hashable {
    let id: String
    let name: String
    let city: String?
}

struct Fair: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let status: String
    let startsAt: String?
    let endsAt: String?
    /// Vienen de GET /fairs/my-assignments: son opcionales porque una feria
    /// puede no tener sede asignada.
    let organization: FairOrganization?
    let site: FairSite?

    enum CodingKeys: String, CodingKey {
        case id, name, description, status, organization, site
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }

    static func == (lhs: Fair, rhs: Fair) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
