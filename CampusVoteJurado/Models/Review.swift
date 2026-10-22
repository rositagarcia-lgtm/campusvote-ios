import Foundation

/// Lista de GET /fairs/{fairId}/review-projects.
/// Acepta `{ summary, projects }` o un arreglo de proyectos.
struct ReviewList: Decodable {
    let summary: ReviewSummary
    let projects: [ReviewProject]
    let access: ReviewAccess
    let scope: ReviewScope?

    enum CodingKeys: String, CodingKey {
        case summary
        case projects
        case items, scope, fair
    }

    init(summary: ReviewSummary, projects: [ReviewProject]) {
        self.scope = nil
        self.access = ReviewAccess()
        self.summary = summary
        self.projects = projects
    }

    init(from decoder: Decoder) throws {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        let nested = try values?.decodeIfPresent(ReviewAccess.self, forKey: .fair)
        access = ((try? ReviewAccess(from: decoder)) ?? ReviewAccess()).merging(nested ?? ReviewAccess())
        let rawScope = try values?.decodeIfPresent(String.self, forKey: .scope)
        scope = rawScope == "all" ? .all : (rawScope == "mine" ? .assigned : nil)
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

extension KeyedDecodingContainer {
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
