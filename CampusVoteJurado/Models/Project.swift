import Foundation

/// Proyecto aprobado que un JURY puede evaluar (mapApprovedProject).
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

    /// Número de stand tal como se muestra en las tarjetas (ej. "A1").
    var tableNumber: String? {
        standCode
    }

    var category: String? {
        categoryName
    }

    var isEvaluated: Bool {
        status?.uppercased() == "EVALUATED"
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
    }

    // MARK: - Sub-objetos anidados (category { id, name }, stand { id, code })

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        status = try container.decodeIfPresent(String.self, forKey: .status)

        if let category = try container.decodeIfPresent(NestedCategory.self, forKey: .category) {
            categoryId = category.id
            categoryName = category.name
        } else {
            categoryId = nil
            categoryName = nil
        }

        if let stand = try container.decodeIfPresent(NestedStand.self, forKey: .stand) {
            standId = stand.id
            standCode = stand.code
        } else {
            standId = nil
            standCode = nil
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
        standCode: String? = nil
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
    }

    private struct NestedCategory: Decodable {
        let id: String
        let name: String
    }

    private struct NestedStand: Decodable {
        let id: String
        let code: String
    }
}

typealias ProjectCard = Project

/// Detalle de proyecto para revisión del JURY (mapProjectReview).
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
        case projectId = "project_id"
        case fairId = "fair_id"
        case name
        case description
        case logoUrl = "logo_url"
        case coverUrl = "cover_url"
        case projectUrl = "project_url"
        case status
        case category
        case stand
        case members
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decode(String.self, forKey: .projectId)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        projectUrl = try container.decodeIfPresent(String.self, forKey: .projectUrl)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        members = (try container.decodeIfPresent([Member].self, forKey: .members)) ?? []

        if let category = try container.decodeIfPresent(NestedItem.self, forKey: .category) {
            categoryId = category.id
            categoryName = category.name
        } else {
            categoryId = nil
            categoryName = nil
        }

        if let stand = try container.decodeIfPresent(NestedItem.self, forKey: .stand) {
            standId = stand.id
            standCode = stand.code
        } else {
            standId = nil
            standCode = nil
        }
    }

    private struct NestedItem: Decodable {
        let id: String
        let name: String?
        let code: String?
    }
}

/// Categoría de la feria (mapCategory).
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

/// Stand de la feria (mapStand).
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

/// Respuesta de GET /fairs/:id/categories.
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

/// Respuesta de GET /fairs/:id/stands.
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