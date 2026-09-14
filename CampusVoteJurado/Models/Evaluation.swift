import Foundation

<<<<<<< HEAD
/// Evaluación de un proyecto hecha por este jurado.
struct Evaluation: Decodable, Hashable, Identifiable {
    let id: String
    let projectId: String
    /// Suma de las notas de todos los criterios.
    let totalScore: Double
    let comment: String?
    let project: ProjectSummary?
    let details: [EvaluationDetail]
    /// Momento en que se guardó la evaluación (updated_at del backend).
    let updatedAt: Date?
}

struct ProjectSummary: Decodable, Hashable {
    let id: String
    let name: String
}

struct EvaluationDetail: Decodable, Hashable {
    let criterionId: String
    let criterionName: String?
    let score: Double
}

/// Cuerpo de POST /fairs/:id/evaluations. Las claves van en snake_case.
struct EvaluationInput: Encodable, Hashable {
    let projectId: String
    /// Una nota por CADA criterio de la rúbrica, dentro de su rango.
    let scores: [ScoreInput]
    let comment: String?

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case scores
        case comment
    }
}

struct ScoreInput: Encodable, Hashable {
=======
/// Puntuación de un criterio al enviar una evaluación.
struct ScoreInput: Codable {
>>>>>>> c26b2aa (fix: codikey por Json)
    let criterionId: String
    let score: Double

    enum CodingKeys: String, CodingKey {
        case criterionId = "criterion_id"
        case score
    }
}

/// Cuerpo de POST/PUT /fairs/:id/evaluations.
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

/// Evaluación tal como la devuelve el backend (mapEvaluation).
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

    /// Proyecto embebido (mapEvaluation.project): { id, name, description, status }.
    let project: NestedProject?

    struct NestedProject: Decodable {
        let id: String
        let name: String
        let description: String?
        let status: String?
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

/// Panel de avance del JURY en una feria (GET /fairs/my-progress/:fairId).
struct JuryProgress: Decodable {
    let fairId: String
    let fairName: String?
    let fairStatus: String?
    let declaration: Declaration?
    let totalProjects: Int
    let evaluatedProjects: Int
    let remaining: Int
    let progressPercentage: Double?
    let evaluations: [Evaluation]?

    enum CodingKeys: String, CodingKey {
        case fairId = "fair_id"
        case fairName = "fair_name"
        case fairStatus = "fair_status"
        case declaration
        case totalProjects = "total_projects"
        case evaluatedProjects = "evaluated_projects"
        case remaining
        case progressPercentage = "progress_percentage"
        case evaluations
    }
}