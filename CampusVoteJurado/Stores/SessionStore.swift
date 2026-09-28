import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {

    enum Phase: Equatable {
        case checking
        case signedOut
        case needsCode(tempToken: String)
        case signedIn(User)
    }

    private(set) var phase: Phase = .checking
    private(set) var isWorking = false
    var errorMessage: String?
    private(set) var pendingEmail = ""

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func restore() async {
        errorMessage = nil
        guard api.hasSavedSession, let user = SessionArchive.load(), user.isJury else {
            api.clearTokens()
            SessionArchive.clear()
            InstitutionAppearance.reset()
            phase = .signedOut
            return
        }

        isWorking = true
        defer { isWorking = false }

        if let organizationId = user.organizationId {
            await loadBrand(organizationId: organizationId)
        }
        phase = .signedIn(user)
    }

    func login(email: String, password: String) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else {
            errorMessage = "Ingresa tu correo institucional."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Ingresa tu contraseña."
            return
        }

        pendingEmail = cleanEmail
        await run {
            let result = try await api.send(
                .login(email: cleanEmail, password: password),
                as: AuthResult.self
            )

            let tempToken = result.tempToken
            let needsEmailCode = result.requiresEmailOtp == true || (tempToken != nil && result.token == nil)
            if needsEmailCode, let tempToken {
                if let email = result.email, !email.isEmpty {
                    pendingEmail = email
                }
                phase = .needsCode(tempToken: tempToken)
            } else {
                try await finish(result)
            }
        }
    }

    func verifyCode(_ code: String) async {
        guard case .needsCode(let tempToken) = phase else { return }
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanCode.count == 6, cleanCode.allSatisfy(\.isNumber) else {
            errorMessage = "El código debe tener 6 dígitos."
            return
        }

        await run {
            let result = try await api.send(
                .verifyEmailCode(code: cleanCode, tempToken: tempToken),
                as: AuthResult.self
            )
            try await finish(result)
        }
    }

    func resendCode() async {
        guard case .needsCode = phase else { return }
        guard !pendingEmail.isEmpty else {
            errorMessage = "No tengo el correo para reenviar el código."
            return
        }
        await run {
            try await api.send(.resendEmailCode(email: pendingEmail))
        }
    }

    func cancelCode() {
        errorMessage = nil
        pendingEmail = ""
        phase = .signedOut
    }

    func logout() async {
        api.clearTokens()
        SessionArchive.clear()
        InstitutionAppearance.reset()
        errorMessage = nil
        pendingEmail = ""
        phase = .signedOut
    }

    private func finish(_ result: AuthResult) async throws {
        guard let token = result.token else {
            throw APIError.decoding("La verificación no devolvió el token de sesión.")
        }
        guard let user = result.user else {
            throw APIError.decoding("La verificación no devolvió el usuario.")
        }
        guard user.isJury else {
            throw APIError.server(
                status: 403,
                code: "FORBIDDEN",
                message: "Esta aplicación es solo para el rol JURY. Tu cuenta tiene el rol \(user.role)."
            )
        }
        guard let organizationId = user.organizationId, !organizationId.isEmpty else {
            throw APIError.decoding("La sesión no trae la institución del jurado.")
        }

        api.saveTokens(access: token, refresh: nil)
        SessionArchive.save(user)
        await loadBrand(organizationId: organizationId)
        phase = .signedIn(user)
    }

    private func loadBrand(organizationId: String) async {
        do {
            let brand = try await api.send(.organization(id: organizationId), as: OrganizationBrand.self)
            InstitutionAppearance.apply(brand)
        } catch {
            InstitutionAppearance.reset()
        }
    }

    private func run(_ work: () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            errorMessage = error.userMessage
        }
    }
}

enum SessionArchive {
    private static let key = "campusvote.jury.user"

    static func save(_ user: User) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> User? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
