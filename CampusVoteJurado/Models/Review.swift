import Foundation

struct ReviewList: Decodable {
    let summary: ReviewSummary
    let projects: [ReviewProject]
    let access: ReviewAccess
    let scope: ReviewScope?

    enum CodingKeys: String, CodingKey {
        case summary
        case projects
        case scope, fair
    }

    init(summary: ReviewSummary, projects: [ReviewProject]) {
        self.scope = nil
        self.access = ReviewAccess()
        self.summary = summary
        self.projects = projects
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let nested = try values.decodeIfPresent(ReviewAccess.self, forKey: .fair)
        access = try ReviewAccess(from: decoder).merging(nested ?? ReviewAccess())
        scope = Self.scope(from: try values.decodeIfPresent(String.self, forKey: .scope))
        // Ambos endpoints de reseñas entregan { summary, projects }.
        // Un elemento inválido debe producir error, nunca desaparecer de la lista.
        projects = try values.decode([ReviewProject].self, forKey: .projects)
        summary = try values.decode(ReviewSummary.self, forKey: .summary)
        guard summary == ReviewSummary(projects: projects) else {
            throw DecodingError.dataCorruptedError(
                forKey: .summary, in: values,
                debugDescription: "El resumen no coincide con los proyectos recibidos."
            )
        }
    }

    private static func scope(from raw: String?) -> ReviewScope? {
        switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "all", "fair", "everyone": return .all
        case "mine", "assigned", "my_categories", "categories": return .assigned
        default: return nil
        }
    }
}

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
        guard let rated = container.decodeLossyInt(forKey: .rated),
              let total = container.decodeLossyInt(forKey: .total) else {
            throw DecodingError.dataCorruptedError(
                forKey: .total, in: container,
                debugDescription: "El resumen requiere total y rated numéricos."
            )
        }
        self.rated = rated
        self.total = total
    }
}

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
        let text = (try? container.decodeIfPresent(String.self, forKey: .comment))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        comment = (text?.isEmpty == false) ? text : nil
    }
}

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
