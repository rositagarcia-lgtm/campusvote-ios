import Foundation

/// Ficha pública de GET /public/fairs/{fairId}/projects/{projectId}.
/// No incluye datos personales ni evaluación.
struct PublicProject: Decodable, Hashable {
    let id: String
    let name: String
    let description: String?
    let logoUrl: String?
    let coverUrl: String?
    let fairId: String?
    let fairName: String?
    let fairStatus: String?
    let organizationName: String?
    let organizationLogo: String?
    let categoryName: String?
    let standCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case logoUrl = "logo_url"
        case coverUrl = "cover_url"
        case fair
        case organization
        case category
        case standCode = "stand_code"
    }

    private struct NestedFair: Decodable {
        let id: String?
        let name: String?
        let status: String?
    }

    private struct NestedOrganization: Decodable {
        let name: String?
        let logo: String?
    }

    private struct NestedCategory: Decodable {
        let name: String?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        standCode = try container.decodeIfPresent(String.self, forKey: .standCode)

        let fair = try container.decodeIfPresent(NestedFair.self, forKey: .fair)
        fairId = fair?.id
        fairName = fair?.name
        fairStatus = fair?.status

        let organization = try container.decodeIfPresent(NestedOrganization.self, forKey: .organization)
        organizationName = organization?.name
        organizationLogo = organization?.logo

        if let value = try? container.decodeIfPresent(String.self, forKey: .category) {
            categoryName = value
        } else if let category = try? container.decodeIfPresent(NestedCategory.self, forKey: .category) {
            categoryName = category.name
        } else {
            categoryName = nil
        }
    }
}

typealias ProjectCard = Project
