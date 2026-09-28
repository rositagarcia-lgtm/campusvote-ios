import Foundation

struct Criterion: Decodable, Hashable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let position: Int
    let isActive: Bool
    let minScore: Double
    let maxScore: Double

    enum CodingKeys: String, CodingKey {
        case id, name, description, position
        case isActive = "is_active"
        case minScore = "min_score"
        case maxScore = "max_score"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Criterio"
        description = try container.decodeIfPresent(String.self, forKey: .description)
        position = try container.decodeIfPresent(Int.self, forKey: .position) ?? 0
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        minScore = try container.decodeIfPresent(Double.self, forKey: .minScore) ?? 0
        maxScore = try container.decodeIfPresent(Double.self, forKey: .maxScore) ?? 0
    }
}

struct Rubric: Decodable, Hashable {
    let id: String
    let name: String
    let criteria: [Criterion]

    var orderedCriteria: [Criterion] {
        criteria.filter { $0.isActive }.sorted { $0.position < $1.position }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, criteria
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? "rubric"
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Rúbrica"
        criteria = try container.decodeIfPresent([Criterion].self, forKey: .criteria) ?? []
    }
}

struct SavedCheck: Decodable, Hashable {
    let criterionId: String
    let checked: Bool

    enum CodingKeys: String, CodingKey {
        case criterionId = "criterion_id"
        case checked
    }
}

struct SavedRubric: Decodable {
    let responses: [SavedCheck]
    let isSubmitted: Bool
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case responses, submitted, finalized, status, score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        responses = try container.decodeIfPresent([SavedCheck].self, forKey: .responses) ?? []
        score = try container.decodeIfPresent(Double.self, forKey: .score)
        if let submitted = try container.decodeIfPresent(Bool.self, forKey: .submitted) {
            isSubmitted = submitted
        } else if let finalized = try container.decodeIfPresent(Bool.self, forKey: .finalized) {
            isSubmitted = finalized
        } else if let status = try container.decodeIfPresent(String.self, forKey: .status) {
            isSubmitted = ["SUBMITTED", "FINAL", "FINALIZED"].contains(status.uppercased())
        } else {
            isSubmitted = score != nil
        }
    }

    func isChecked(_ criterionId: String) -> Bool {
        responses.first { $0.criterionId == criterionId }?.checked ?? false
    }
}

struct VotingStatus: Decodable {
    let hasVoted: Bool
    let votedAt: String?

    enum CodingKeys: String, CodingKey {
        case hasVoted = "has_voted"
        case votedAt = "voted_at"
    }
}

struct VoteReceipt: Decodable {
    let status: String
    let receiptCode: String

    enum CodingKeys: String, CodingKey {
        case status
        case receiptCode = "receipt_code"
    }
}

struct CategoryRubricSummary: Decodable, Identifiable {
    let id: String
    let categoryName: String
    let submittedCount: Int
    let checkedCount: Int
    let criteriaCount: Int
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case categoryName = "category_name"
        case submitted
        case checkedCount = "checked_count"
        case criteriaCount = "criteria_count"
        case score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nested = try container.decodeIfPresent(NestedCategory.self, forKey: .category)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? nested?.id ?? UUID().uuidString
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? nested?.name
            ?? "Categoría"
        if let count = try? container.decode(Int.self, forKey: .submitted) {
            submittedCount = count
        } else if let flag = try? container.decode(Bool.self, forKey: .submitted) {
            submittedCount = flag ? 1 : 0
        } else {
            submittedCount = 0
        }
        checkedCount = try container.decodeIfPresent(Int.self, forKey: .checkedCount) ?? 0
        criteriaCount = try container.decodeIfPresent(Int.self, forKey: .criteriaCount) ?? 0
        score = try container.decodeIfPresent(Double.self, forKey: .score)
    }

    private struct NestedCategory: Decodable {
        let id: String?
        let name: String?
    }
}

struct MyRubricsPayload: Decodable {
    let groups: [CategoryRubricSummary]

    init(from decoder: Decoder) throws {
        if let groups = try? [CategoryRubricSummary](from: decoder) {
            self.groups = groups
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groups = try container.decodeIfPresent([CategoryRubricSummary].self, forKey: .categories)
            ?? container.decodeIfPresent([CategoryRubricSummary].self, forKey: .rubrics)
            ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case categories, rubrics
    }
}
