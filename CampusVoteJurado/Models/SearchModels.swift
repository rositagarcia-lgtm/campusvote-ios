import Foundation

/// Resultado de la búsqueda de proyectos en modo observador.
/// El backend devuelve el proyecto (mapApprovedProject) más sus agregados
/// de calificación (average_score, ratings_count). Los agregados son
/// opcionales: si el backend aún no los incluye, la UI oculta la nota.
struct ProjectSearchResult: Decodable, Identifiable, Hashable {
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
    /// Nota promedio de todas las calificaciones del proyecto.
    let averageScore: Double?
    /// Cantidad de calificaciones recibidas.
    let ratingsCount: Int?

    private struct NestedItem: Decodable {
        let id: String
        let name: String?
        let code: String?
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case status
        case fairId = "fair_id"
        case logoUrl = "logo_url"
        case coverUrl = "cover_url"
        case category
        case stand
        case averageScore = "average_score"
        case ratingsCount = "ratings_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fairId = try container.decodeIfPresent(String.self, forKey: .fairId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        averageScore = try container.decodeIfPresent(Double.self, forKey: .averageScore)
        ratingsCount = try container.decodeIfPresent(Int.self, forKey: .ratingsCount)

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
}

/// Orden de los resultados de la búsqueda (parámetro `sort` del backend).
enum SearchSort: String, CaseIterable, Identifiable {
    case name = "name"
    case scoreDesc = "score_desc"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name:
            return "Nombre (A–Z)"
        case .scoreDesc:
            return "Mejor nota"
        }
    }
}