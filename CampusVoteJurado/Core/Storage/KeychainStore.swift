import Foundation
import Security

/// Persistencia de los tokens de sesión en el llavero del dispositivo.
enum KeychainStore {
    /// Cuentas del llavero: access token (Bearer) y refresh token.
    enum Account: String {
        case access = "authToken"
        case refresh = "refreshToken"
    }

    private static let service = "com.campusvote.jurado"

    // MARK: - Lectura

    static func readToken(for account: Account) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    // MARK: - Escritura

    @discardableResult
    static func save(_ token: String, for account: Account) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue
        ]
        let update: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(lookup as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        guard updateStatus == errSecItemNotFound else { return false }

        var item = lookup
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Borrado

    static func deleteToken(for account: Account) {
        secItemDelete(for: account)
    }

    private static func secItemDelete(for account: Account) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Alias compatibles (token de acceso por defecto)

    static func getToken() -> String? {
        readToken(for: .access)
    }

    static func saveToken(_ token: String) {
        _ = save(token, for: .access)
    }

    static func deleteToken() {
        deleteToken(for: .access)
    }
}
