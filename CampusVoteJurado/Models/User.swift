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
        let otp = try container.decodeIfPresent(Bool.self, forKey: .requiresEmailOtp)
        let otpSnake = try container.decodeIfPresent(Bool.self, forKey: .requiresEmailOtpSnake)
        requiresEmailOtp = otp ?? otpSnake

        let tokenValue = try container.decodeIfPresent(String.self, forKey: .tempToken)
        let tokenSnake = try container.decodeIfPresent(String.self, forKey: .tempTokenSnake)
        tempToken = tokenValue ?? tokenSnake

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
    let orgType: String?

    var kindLabel: String? {
        guard let raw = orgType?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        switch raw.uppercased() {
        case "UNIVERSITY": return "Universidad"
        case "INSTITUTE": return "Instituto de Educación Superior"
        case "SCHOOL": return "Colegio"
        case "COMPANY": return "Empresa"
        case "ASSOCIATION": return "Asociación"
        default: return raw
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case logo
        case logoUrl = "logo_url"
        case primaryColor
        case primaryColorSnake = "primary_color"
        case secondaryColor
        case secondaryColorSnake = "secondary_color"
        case orgType = "org_type"
        case organizationType = "organization_type"
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Institución"

        let logoValue = try container.decodeIfPresent(String.self, forKey: .logo)
        let logoURL = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        logo = logoValue ?? logoURL

        let primary = try container.decodeIfPresent(String.self, forKey: .primaryColor)
        let primarySnake = try container.decodeIfPresent(String.self, forKey: .primaryColorSnake)
        primaryColor = primary ?? primarySnake

        let secondary = try container.decodeIfPresent(String.self, forKey: .secondaryColor)
        let secondarySnake = try container.decodeIfPresent(String.self, forKey: .secondaryColorSnake)
        secondaryColor = secondary ?? secondarySnake

        let org = try container.decodeIfPresent(String.self, forKey: .orgType)
        let organization = try container.decodeIfPresent(String.self, forKey: .organizationType)
        let plainType = try container.decodeIfPresent(String.self, forKey: .type)
        orgType = org ?? organization ?? plainType
    }
}
