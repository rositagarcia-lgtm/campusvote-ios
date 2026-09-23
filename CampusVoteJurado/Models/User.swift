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
    /// La cuenta aún no tiene autenticador: toca configurarlo (QR).
    let requiresOnboarding: Bool?
    let requiresTotp: Bool?
    let token: String?
    let refreshToken: String?
    /// Solo llega con requiresOnboarding o requiresTotp: autentica los pasos
    /// previos a la sesión (configurar el QR o enviar el código).
    let tempToken: String?
    let user: User?
}

/// Datos para configurar el autenticador por primera vez
/// (POST /auth/onboarding/totp/setup). Claves en camelCase.
struct TotpSetup: Decodable {
    /// Imagen del QR en formato "data:image/png;base64,…".
    let qrCode: String
    /// El mismo secreto en texto, para escribirlo a mano si no puede escanear.
    let secret: String
    let uri: String
}

/// Respuesta al activar el 2FA: los códigos de respaldo se muestran UNA vez.
struct TotpEnabled: Decodable {
    let backupCodes: [String]
}