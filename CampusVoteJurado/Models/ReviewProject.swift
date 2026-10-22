import Foundation

/// Tarjeta de un proyecto en la lista de reseñas.
struct ReviewProject: Identifiable, Decodable, Hashable {
    let id: String
    let fairId: String?
    let fairName: String?
    let name: String
    let coverUrl: String?
    let categoryId: String?
    let categoryName: String?
    let standCode: String?
    let teamName: String?
    let myRating: Int?
    let myComment: String?
    let access: ReviewAccess
    let inMyCategories: Bool?

    var sinResena: Bool {
        myRating == nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case inMyCategories = "in_my_categories"
        case projectId = "project_id"
        case fairId = "fair_id"
        case fairName = "fair_name"
        case name
        case coverUrl = "cover_url"
        case category
        case categoryId = "category_id"
        case categoryName = "category_name"
        case stand
        case standCode = "stand_code"
        case teamName = "team_name"
        case team
        case myRating = "my_rating"
        case myComment = "my_comment"
    }

    init(
        id: String,
        fairId: String? = nil,
        fairName: String? = nil,
        name: String,
        coverUrl: String? = nil,
        categoryId: String? = nil,
        categoryName: String? = nil,
        standCode: String? = nil,
        teamName: String? = nil,
        myRating: Int? = nil,
        myComment: String? = nil,
        access: ReviewAccess = ReviewAccess(),
        inMyCategories: Bool? = nil
    ) {
        self.access = access
        self.inMyCategories = inMyCategories
        self.id = id
        self.fairId = fairId
        self.fairName = fairName
        self.name = name
        self.coverUrl = coverUrl
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.standCode = standCode
        self.teamName = teamName
        self.myRating = myRating
        self.myComment = myComment
    }

    init(from decoder: Decoder) throws {
        access = try ReviewAccess(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inMyCategories = try container.decodeIfPresent(Bool.self, forKey: .inMyCategories)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .projectId)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId)
        fairName = try container.decodeIfPresent(String.self, forKey: .fairName)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Proyecto"
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)

        if let category = try? container.decode(NestedCategory.self, forKey: .category) {
            categoryId = category.id
            categoryName = category.name
        } else if let categoryName = try? container.decodeIfPresent(String.self, forKey: .category) {
            categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
            self.categoryName = categoryName
        } else {
            categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
            categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        }

        let flatStand = try container.decodeIfPresent(String.self, forKey: .standCode)
        if let stand = try? container.decode(NestedStand.self, forKey: .stand) {
            standCode = stand.code ?? stand.name ?? flatStand
        } else {
            standCode = flatStand
        }

        let namedTeam = try container.decodeIfPresent(String.self, forKey: .teamName)
        let plainTeam = try container.decodeIfPresent(String.self, forKey: .team)
        let team = namedTeam ?? plainTeam
        teamName = (team?.isEmpty == false) ? team : nil

        myRating = container.decodeLossyInt(forKey: .myRating)
        let comment = try container.decodeIfPresent(String.self, forKey: .myComment)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        myComment = (comment?.isEmpty == false) ? comment : nil
    }

    private struct NestedCategory: Decodable {
        let id: String?
        let name: String?
    }

    private struct NestedStand: Decodable {
        let code: String?
        let name: String?
    }
}
