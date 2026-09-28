import Foundation

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

    var tableNumber: String? { standCode }
    var category: String? { categoryName }

    var isEvaluated: Bool {
        status?.uppercased() == "EVALUATED"
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, status, category, stand
        case fairId = "fair_id"
        case logoUrl = "logo_url"
        case coverUrl = "cover_url"
        case categoryId = "category_id"
        case categoryName = "category_name"
        case standId = "stand_id"
        case standCode = "stand_code"
        case imageUrls = "image_urls"
        case videoUrl = "video_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Proyecto"
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        imageUrls = Self.readUrls(container, key: .imageUrls)

        let flatCategoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
        let flatCategoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        if let category = try? container.decode(NestedCategory.self, forKey: .category) {
            categoryId = category.id ?? flatCategoryId
            categoryName = category.name ?? flatCategoryName
        } else if let name = try? container.decode(String.self, forKey: .category) {
            categoryId = flatCategoryId
            categoryName = name
        } else {
            categoryId = flatCategoryId
            categoryName = flatCategoryName
        }

        let flatStandId = try container.decodeIfPresent(String.self, forKey: .standId)
        let flatStandCode = try container.decodeIfPresent(String.self, forKey: .standCode)
        if let stand = try? container.decode(NestedStand.self, forKey: .stand) {
            standId = stand.id ?? flatStandId
            standCode = stand.code ?? stand.name ?? flatStandCode
        } else if let code = try? container.decode(String.self, forKey: .stand) {
            standId = flatStandId
            standCode = code
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

    private static func readUrls(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> [String] {
        if let list = try? container.decode([String].self, forKey: key) {
            return list
        }
        if let boxes = try? container.decode([URLBox].self, forKey: key) {
            return boxes.compactMap { $0.url ?? $0.src }
        }
        return []
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

    private struct URLBox: Decodable {
        let url: String?
        let src: String?
    }
}

typealias ProjectCard = Project

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
    let criteria: [Criterion]
    let members: [Member]

    var activeCriteria: [Criterion] {
        criteria.filter { $0.isActive }.sorted { $0.position < $1.position }
    }

    var asProject: Project {
        Project(
            id: projectId,
            fairId: fairId,
            name: name,
            description: description,
            logoUrl: logoUrl,
            coverUrl: coverUrl,
            status: status,
            categoryId: categoryId,
            categoryName: categoryName,
            standId: standId,
            standCode: standCode,
            imageUrls: imageUrls,
            videoUrl: videoUrl
        )
    }

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

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
            firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
            lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
            role = try container.decodeIfPresent(String.self, forKey: .role)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, status, category, stand, members, rubric
        case projectId = "project_id"
        case fairId = "fair_id"
        case logoUrl = "logo_url"
        case coverUrl = "cover_url"
        case projectUrl = "project_url"
        case videoUrl = "video_url"
        case imageUrls = "image_urls"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
            ?? container.decode(String.self, forKey: .id)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Proyecto"
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        projectUrl = try container.decodeIfPresent(String.self, forKey: .projectUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        members = (try? container.decode([Member].self, forKey: .members)) ?? []
        criteria = (try? container.decode(NestedRubric.self, forKey: .rubric))?.criteria ?? []
        imageUrls = Self.readUrls(container)

        if let category = try? container.decode(NestedItem.self, forKey: .category) {
            categoryId = category.id
            categoryName = category.name
        } else if let name = try? container.decode(String.self, forKey: .category) {
            categoryId = nil
            categoryName = name
        } else {
            categoryId = nil
            categoryName = nil
        }

        if let stand = try? container.decode(NestedItem.self, forKey: .stand) {
            standId = stand.id
            standCode = stand.code ?? stand.name
        } else if let code = try? container.decode(String.self, forKey: .stand) {
            standId = nil
            standCode = code
        } else {
            standId = nil
            standCode = nil
        }
    }

    private static func readUrls(_ container: KeyedDecodingContainer<CodingKeys>) -> [String] {
        if let list = try? container.decode([String].self, forKey: .imageUrls) { return list }
        if let boxes = try? container.decode([URLBox].self, forKey: .imageUrls) {
            return boxes.compactMap { $0.url ?? $0.src }
        }
        return []
    }

    private struct NestedItem: Decodable {
        let id: String?
        let name: String?
        let code: String?
    }

    private struct NestedRubric: Decodable {
        let criteria: [Criterion]
    }

    private struct URLBox: Decodable {
        let url: String?
        let src: String?
    }
}

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let fairId: String?
    let name: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case fairId = "fair_id"
    }
}

struct Stand: Codable, Identifiable, Hashable {
    let id: String
    let fairId: String?
    let code: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id, code, description
        case fairId = "fair_id"
    }
}

struct CategoryList: Decodable {
    let fairId: String?
    let fairName: String?
    let count: Int?
    let categories: [Category]

    enum CodingKeys: String, CodingKey {
        case fairId = "fair_id"
        case fairName = "fair_name"
        case count
        case categories
    }
}

struct StandList: Decodable {
    let fairId: String?
    let fairName: String?
    let count: Int?
    let stands: [Stand]

    enum CodingKeys: String, CodingKey {
        case fairId = "fair_id"
        case fairName = "fair_name"
        case count
        case stands
    }
}
