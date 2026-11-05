import Foundation

struct ReviewList: Decodable {
    let summary: ReviewSummary
    let projects: [ReviewProject]
    let access: ReviewAccess
    let scope: ReviewScope?

    enum CodingKeys: String, CodingKey {
        case summary
        case projects
        case items, results, data, scope, fair
        case reviewProjects = "review_projects"
    }

    init(summary: ReviewSummary, projects: [ReviewProject]) {
        self.scope = nil
        self.access = ReviewAccess()
        self.summary = summary
        self.projects = projects
    }

    init(from decoder: Decoder) throws {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        let nested = try? values?.decodeIfPresent(ReviewAccess.self, forKey: .fair)
        access = ((try? ReviewAccess(from: decoder)) ?? ReviewAccess()).merging(nested ?? ReviewAccess())
        scope = Self.scope(from: try? values?.decodeIfPresent(String.self, forKey: .scope))

        if let container = values {
            for key in [CodingKeys.projects, .items, .results, .reviewProjects, .data] where container.contains(key) {
                if let projects = Self.projects(in: container, key: key) {
                    self.projects = projects
                    self.summary = (try? container.decodeIfPresent(ReviewSummary.self, forKey: .summary))
                        ?? ReviewSummary(projects: projects)
                    return
                }
            }
        }

        if let projects = try? [OptionalProject](from: decoder).compactMap(\.project) {
            self.projects = projects
            self.summary = ReviewSummary(projects: projects)
            return
        }

        self.projects = []
        self.summary = ReviewSummary(rated: 0, total: 0)
    }

    private static func scope(from raw: String?) -> ReviewScope? {
        switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "all", "fair", "everyone": return .all
        case "mine", "assigned", "my_categories", "categories": return .assigned
        default: return nil
        }
    }

    private static func projects(
        in container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> [ReviewProject]? {
        (try? container.decode([OptionalProject].self, forKey: key))?.compactMap(\.project)
    }
}

private struct OptionalProject: Decodable {
    let project: ReviewProject?
    init(from decoder: Decoder) throws {
        project = try? ReviewProject(from: decoder)
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
        rated = container.decodeLossyInt(forKey: .rated) ?? 0
        total = container.decodeLossyInt(forKey: .total) ?? 0
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
