import Foundation

struct Declaration: Codable, Identifiable {
    let id: String?
    let fairId: String?
    let signed: Bool?
    let signedAt: String?
    let statement: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fairId = "fair_id"
        case signed
        case signedAt = "signed_at"
        case statement
    }
}

struct DeclarationResponse: Decodable {
    let fairId: String?
    let signed: Bool
    let declaration: Declaration?
    let statement: String?

    /// Texto guardado en el servidor, venga suelto o dentro de la declaración.
    var serverStatement: String? {
        let nested = declaration?.statement?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let nested, !nested.isEmpty { return nested }
        let top = statement?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let top, !top.isEmpty { return top }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case fairId = "fair_id"
        case signed
        case declaration
        case statement
    }
}

struct DeclarationRequest: Encodable {
    let statement: String
}

/// Respuesta de firmar la declaración: el objeto plano o { signed, declaration }.
struct DeclarationAck: Decodable {
    let signedAt: String?

    enum CodingKeys: String, CodingKey {
        case signed
        case signedAt = "signed_at"
        case declaration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let nested = try container.decodeIfPresent(Declaration.self, forKey: .declaration) {
            signedAt = nested.signedAt
        } else {
            signedAt = try container.decodeIfPresent(String.self, forKey: .signedAt)
        }
    }
}
