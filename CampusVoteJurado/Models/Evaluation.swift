import Foundation

struct ScoreInput: Codable {
    let criterionId: String
    let score: Double

    enum CodingKeys: String, CodingKey {
        case criterionId = "criterion_id"
        case score
    }
}

struct EvaluationInput: Codable {
    let projectId: String
    let comment: String?
    let scores: [ScoreInput]

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case comment
        case scores
    }
}

struct Evaluation: Decodable, Identifiable {
    let id: String
    let fairId: String?
    let projectId: String?
    let rubricId: String?
    let totalScore: Double?
    let comment: String?
    let createdAt: String?
    let updatedAt: String?

    struct Detail: Decodable, Identifiable {
        let id: String?
        let criterionId: String?
        let criterionName: String?
        let minScore: Double?
        let maxScore: Double?
        let score: Double

        enum CodingKeys: String, CodingKey {
            case id
            case criterionId = "criterion_id"
            case criterionName = "criterion_name"
            case minScore = "min_score"
            case maxScore = "max_score"
            case score
        }
    }

    let details: [Detail]?
    let project: NestedProject?

    struct NestedProject: Decodable {
        let id: String
        let name: String
        let description: String?
        let status: String?
    }

    var resolvedProjectId: String? {
        projectId ?? project?.id
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fairId = "fair_id"
        case projectId = "project_id"
        case rubricId = "rubric_id"
        case totalScore = "total_score"
        case comment
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case details
        case project
    }
}

struct JuryProgress: Decodable {
    let fairId: String
    let fairName: String?
    let fairStatus: String?
    let declaration: Declaration?
    let totalProjects: Int
    let completedProjects: Int
    let pendingProjects: Int
    let progressPercentage: Double?

    var evaluatedProjects: Int { completedProjects }
    var remaining: Int { pendingProjects }

    var declarationSigned: Bool {
        declaration?.signed == true || declaration?.signedAt?.isEmpty == false
    }

    enum CodingKeys: String, CodingKey {
        case fairId = "fair_id"
        case fairName = "fair_name"
        case fairStatus = "fair_status"
        case declaration
        case totalProjects = "total_projects"
        case completedProjects = "completed_projects"
        case pendingProjects = "pending_projects"
        case progressPercentage = "progress_percentage"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId) ?? ""
        fairName = try container.decodeIfPresent(String.self, forKey: .fairName)
        fairStatus = try container.decodeIfPresent(String.self, forKey: .fairStatus)
        declaration = try container.decodeIfPresent(Declaration.self, forKey: .declaration)
        totalProjects = try container.decodeIfPresent(Int.self, forKey: .totalProjects) ?? 0
        completedProjects = try container.decodeIfPresent(Int.self, forKey: .completedProjects) ?? 0
        pendingProjects = try container.decodeIfPresent(Int.self, forKey: .pendingProjects) ?? 0
        progressPercentage = try container.decodeIfPresent(Double.self, forKey: .progressPercentage)
    }
}
