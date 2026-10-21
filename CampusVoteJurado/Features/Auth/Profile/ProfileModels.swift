import Foundation

struct JuryProfile: Decodable {
    var firstName: String
    var lastName: String
    let email: String
    let institutionalId: String?
    let documentType: String?
    let documentNumber: String?
    let avatarUrl: String?

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var avatarURL: URL? {
        guard let avatarUrl, let url = URL(string: avatarUrl) else { return nil }
        return url
    }

    var documentKind: String {
        let raw = (documentType ?? "").uppercased()
        if raw.contains("CE") || raw.contains("EXTRAN") { return "CE" }
        return "DNI"
    }

    var documentLine: String {
        let number = documentNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !number.isEmpty else { return "—" }
        let kind = documentType?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let kind, !kind.isEmpty { return "\(kind) \(number)" }
        return number
    }

    init(user: User) {
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        institutionalId = nil
        documentType = nil
        documentNumber = nil
        avatarUrl = nil
    }

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case institutionalId = "institutional_id"
        case documentType = "document_type"
        case documentNumber = "document_number"
        case avatarUrl = "avatar_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        institutionalId = try container.decodeIfPresent(String.self, forKey: .institutionalId)
        documentType = try container.decodeIfPresent(String.self, forKey: .documentType)
        documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
    }
}

struct NameUpdate: Encodable {
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct PasswordUpdate: Encodable {
    let currentPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}
