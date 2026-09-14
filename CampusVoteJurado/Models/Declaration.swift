import Foundation

struct Declaration: Codable, Identifiable {
    let id: String?
    let fairId: String?
    let signedAt: String?
    let statement: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fairId = "fair_id"
        case signedAt = "signed_at"
        case statement
    }
}

struct DeclarationResponse: Decodable {
    let fairId: String?
    let signed: Bool
    let declaration: Declaration?

    enum CodingKeys: String, CodingKey {
        case fairId = "fair_id"
        case signed
        case declaration
    }
}

struct DeclarationRequest: Encodable {
    let statement: String
}
