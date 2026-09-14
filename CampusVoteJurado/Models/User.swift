import Foundation

/// Usuario de la sesión (respuesta de /auth/login, /auth/refresh y /auth/me).
/// El backend lo serializa en snake_case (formatUserResponse).
struct User: Decodable, Hashable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let role: String
    let organizationId: String?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var isJury: Bool {
        role == "JURY"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case firstName = "first_name"
        case lastName = "last_name"
        case organizationId = "organization_id"
    }
}

/// Respuesta del login, del segundo paso del 2FA y de la renovación de sesión.
/// Estas claves van en camelCase en el backend.
struct AuthResult: Decodable {
    let requiresTotp: Bool?
    let token: String?
    let refreshToken: String?
    /// Solo llega si requiresTotp es true: se usa para enviar el código.
    let tempToken: String?
    let user: User?
}