import Foundation

/// Proyecto aprobado de una feria.
struct Project: Identifiable, Decodable, Hashable {
    let id: String
    let fairId: String?
    let name: String
    let description: String?
    let logoUrl: String?
    let coverUrl: String?
    let status: String?
    let categoryId: String?
    let categoryName: String?
    let standId: String?
    let standCode: String?
    let imageUrls: [String]
    let videoUrl: String?

    var tableNumber: String? {
        standCode
    }

    var category: String? {
        categoryName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fairId = "fair_id"
        case name
        case description
        case logoUrl = "logo_url"
        case coverUrl = "cover_url"
        case status
        case categoryId = "category_id"
        case categoryName = "category_name"
        case standId = "stand_id"
        case standCode = "stand_code"
        case category
        case stand
        case imageUrls = "image_urls"
        case videoUrl = "video_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)

        let flatCategoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
        let flatCategoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        if let category = try? container.decode(NestedCategory.self, forKey: .category) {
            categoryId = category.id ?? flatCategoryId
            categoryName = category.name ?? flatCategoryName
        } else {
            categoryId = flatCategoryId
            categoryName = flatCategoryName
        }

        let flatStandId = try container.decodeIfPresent(String.self, forKey: .standId)
        let flatStandCode = try container.decodeIfPresent(String.self, forKey: .standCode)
        if let stand = try? container.decode(NestedStand.self, forKey: .stand) {
            standId = stand.id ?? flatStandId
            standCode = stand.code ?? stand.name ?? flatStandCode
        } else {
            standId = flatStandId
            standCode = flatStandCode
        }
    }

    init(
        id: String,
        fairId: String? = nil,
        name: String,
        description: String? = nil,
        logoUrl: String? = nil,
        coverUrl: String? = nil,
        status: String? = nil,
        categoryId: String? = nil,
        categoryName: String? = nil,
        standId: String? = nil,
        standCode: String? = nil,
        imageUrls: [String] = [],
        videoUrl: String? = nil
    ) {
        self.id = id
        self.fairId = fairId
        self.name = name
        self.description = description
        self.logoUrl = logoUrl
        self.coverUrl = coverUrl
        self.status = status
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.standId = standId
        self.standCode = standCode
        self.imageUrls = imageUrls
        self.videoUrl = videoUrl
    }

    private struct NestedCategory: Decodable {
        let id: String?
        let name: String?
    }

    private struct NestedStand: Decodable {
        let id: String?
        let code: String?
        let name: String?
    }
}

typealias ProjectCard = Project

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

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let fairId: String?
    let name: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fairId = "fair_id"
        case name
        case description
    }
}

struct Stand: Codable, Identifiable, Hashable {
    let id: String
    let fairId: String?
    let code: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fairId = "fair_id"
        case code
        case description
    }
}
