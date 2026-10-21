import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let fairId: String?
    let name: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fairId = "fair_id"
        case name
        case description
    }
}

struct Stand: Codable, Identifiable, Hashable {
    let id: String
    let fairId: String?
    let code: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fairId = "fair_id"
        case code
        case description
    }
}
