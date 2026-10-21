import Foundation

/// Detalle de GET /fairs/{fairId}/projects/{projectId}.
struct ProjectDetail: Decodable {
    let projectId: String
    let fairId: String?
    let name: String
    let description: String?
    let logoUrl: String?
    let coverUrl: String?
    let projectUrl: String?
    let status: String?
    let categoryId: String?
    let categoryName: String?
    let standId: String?
    let standCode: String?
    let imageUrls: [String]
    let videoUrl: String?
    let members: [Member]

    struct Member: Decodable, Identifiable {
        let id: String
        let firstName: String?
        let lastName: String?
        let role: String?

        enum CodingKeys: String, CodingKey {
            case id
            case firstName = "first_name"
            case lastName = "last_name"
            case role
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case fairId = "fair_id"
        case name
        case description
        case logoUrl = "logo_url"
        case coverUrl = "cover_url"
        case projectUrl = "project_url"
        case videoUrl = "video_url"
        case imageUrls = "image_urls"
        case status
        case category
        case categoryId = "category_id"
        case categoryName = "category_name"
        case stand
        case standId = "stand_id"
        case standCode = "stand_code"
        case members
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
            ?? container.decode(String.self, forKey: .id)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        projectUrl = try container.decodeIfPresent(String.self, forKey: .projectUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        status = try container.decodeIfPresent(String.self, forKey: .status)
        members = (try container.decodeIfPresent([Member].self, forKey: .members)) ?? []

        let flatCategoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
        let flatCategoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        if let category = try? container.decode(NestedItem.self, forKey: .category) {
            categoryId = category.id ?? flatCategoryId
            categoryName = category.name ?? flatCategoryName
        } else {
            categoryId = flatCategoryId
            categoryName = flatCategoryName
        }

        let flatStandId = try container.decodeIfPresent(String.self, forKey: .standId)
        let flatStandCode = try container.decodeIfPresent(String.self, forKey: .standCode)
        if let stand = try? container.decode(NestedItem.self, forKey: .stand) {
            standId = stand.id ?? flatStandId
            standCode = stand.code ?? stand.name ?? flatStandCode
        } else {
            standId = flatStandId
            standCode = flatStandCode
        }
    }

    private struct NestedItem: Decodable {
        let id: String?
        let name: String?
        let code: String?
    }
}
