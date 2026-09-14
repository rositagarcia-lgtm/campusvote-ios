import Foundation

/// Rúbrica de la feria (GET /fairs/:id/rubric).
struct Rubric: Decodable, Hashable {
    let id: String
    let name: String
    let criteria: [Criterion]

    /// Criterios en el orden que definió el admin.
    var orderedCriteria: [Criterion] {
        criteria.sorted { $0.position < $1.position }
    }
}

/// Un criterio con su rango de notas. El rango lo define el admin de la feria.
struct Criterion: Decodable, Hashable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let minScore: Double
    let maxScore: Double
    let position: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case minScore = "min_score"
        case maxScore = "max_score"
        case position
    }
}
