import Foundation

/// Lista de GET /fairs/{fairId}/review-projects.
/// Acepta `{ summary, projects }` o un arreglo de proyectos.
struct ReviewList: Decodable {
    let summary: ReviewSummary
    let projects: [ReviewProject]

    enum CodingKeys: String, CodingKey {
        case summary
        case projects
        case items
    }

    init(summary: ReviewSummary, projects: [ReviewProject]) {
        self.summary = summary
        self.projects = projects
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           container.contains(.projects) || container.contains(.items) || container.contains(.summary) {
            let projects = try container.decodeIfPresent([ReviewProject].self, forKey: .projects)
                ?? container.decodeIfPresent([ReviewProject].self, forKey: .items)
                ?? []
            if let summary = try container.decodeIfPresent(ReviewSummary.self, forKey: .summary) {
                self.summary = summary
            } else {
                self.summary = ReviewSummary(projects: projects)
            }
            self.projects = projects
            return
        }

        let projects = try [ReviewProject](from: decoder)
        self.projects = projects
        self.summary = ReviewSummary(projects: projects)
    }
}

/// Encabezado «0 de 3».
struct ReviewSummary: Decodable, Hashable {
    let rated: Int
    let total: Int

    var pending: Int {
        max(total - rated, 0)
    }

    enum CodingKeys: String, CodingKey {
        case rated
        case total
    }

    init(rated: Int, total: Int) {
        self.rated = rated
        self.total = total
    }

    init(projects: [ReviewProject]) {
        rated = projects.filter { $0.myRating != nil }.count
        total = projects.count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rated = container.decodeLossyInt(forKey: .rated) ?? 0
        total = container.decodeLossyInt(forKey: .total) ?? 0
    }
}

/// Tarjeta de un proyecto en la lista de reseñas.
struct ReviewProject: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let coverUrl: String?
    let categoryId: String?
    let categoryName: String?
    let standCode: String?
    let teamName: String?
    let myRating: Int?
    let myComment: String?

    var sinResena: Bool {
        myRating == nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
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
        name: String,
        coverUrl: String? = nil,
        categoryId: String? = nil,
        categoryName: String? = nil,
        standCode: String? = nil,
        teamName: String? = nil,
        myRating: Int? = nil,
        myComment: String? = nil
    ) {
        self.id = id
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
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .projectId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Proyecto"
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)

        if let category = try container.decodeIfPresent(NestedCategory.self, forKey: .category) {
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

/// GET /fairs/{fairId}/projects/{projectId}/rating.
/// `rating` null significa que todavía no hay reseña.
struct ProjectRating: Decodable, Hashable {
    let rating: Int?
    let comment: String?

    var sinResena: Bool {
        rating == nil
    }

    enum CodingKeys: String, CodingKey {
        case rating
        case comment
    }

    init(rating: Int?, comment: String?) {
        self.rating = rating
        self.comment = comment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rating = container.decodeLossyInt(forKey: .rating)
        let text = try container.decodeIfPresent(String.self, forKey: .comment)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        comment = (text?.isEmpty == false) ? text : nil
    }
}

/// Cuerpo del PUT de la misma ruta: `{ "rating": 4, "comment": "..." }`.
struct ReviewPutBody: Encodable {
    let rating: Int
    let comment: String
}

private extension KeyedDecodingContainer {
    func decodeLossyInt(forKey key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(value)
        }
        if let text = try? decodeIfPresent(String.self, forKey: key) {
            return Int(text)
        }
        return nil
    }
}
