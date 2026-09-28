import Foundation

struct User: Codable, Hashable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let role: String
    let organizationId: String?

    var fullName: String {
        let parts = [firstName, lastName].filter { !$0.isEmpty }
        return parts.isEmpty ? email : parts.joined(separator: " ")
    }

    var isJury: Bool {
        role.uppercased() == "JURY"
    }

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case firstName = "first_name"
        case lastName = "last_name"
        case organizationId = "organization_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? ""
        organizationId = try container.decodeIfPresent(String.self, forKey: .organizationId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(organizationId, forKey: .organizationId)
    }
}

struct AuthResult: Decodable {
    let requiresEmailOtp: Bool?
    let tempToken: String?
    let email: String?
    let token: String?
    let user: User?

    enum CodingKeys: String, CodingKey {
        case requiresEmailOtp
        case requiresEmailOtpSnake = "requires_email_otp"
        case tempToken
        case tempTokenSnake = "temp_token"
        case email, token, user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requiresEmailOtp = try container.decodeIfPresent(Bool.self, forKey: .requiresEmailOtp)
            ?? container.decodeIfPresent(Bool.self, forKey: .requiresEmailOtpSnake)
        tempToken = try container.decodeIfPresent(String.self, forKey: .tempToken)
            ?? container.decodeIfPresent(String.self, forKey: .tempTokenSnake)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        user = try container.decodeIfPresent(User.self, forKey: .user)
    }
}

struct OrganizationBrand: Decodable {
    let id: String?
    let name: String
    let logo: String?
    let primaryColor: String?
    let secondaryColor: String?

    enum CodingKeys: String, CodingKey {
        case id, name, logo, primary, secondary, organization
        case logoUrl = "logo_url"
        case primaryColor
        case primaryColorSnake = "primary_color"
        case secondaryColor
        case secondaryColorSnake = "secondary_color"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hasOwnFields = container.contains(.name)
            || container.contains(.primaryColor)
            || container.contains(.primaryColorSnake)
            || container.contains(.primary)
            || container.contains(.logo)
            || container.contains(.logoUrl)
        if !hasOwnFields, let nested = try container.decodeIfPresent(OrganizationBrand.self, forKey: .organization) {
            self = nested
            return
        }
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Institución"
        logo = try container.decodeIfPresent(String.self, forKey: .logo)
            ?? container.decodeIfPresent(String.self, forKey: .logoUrl)
        primaryColor = try container.decodeIfPresent(String.self, forKey: .primaryColor)
            ?? container.decodeIfPresent(String.self, forKey: .primaryColorSnake)
            ?? container.decodeIfPresent(String.self, forKey: .primary)
        secondaryColor = try container.decodeIfPresent(String.self, forKey: .secondaryColor)
            ?? container.decodeIfPresent(String.self, forKey: .secondaryColorSnake)
            ?? container.decodeIfPresent(String.self, forKey: .secondary)
    }
}
