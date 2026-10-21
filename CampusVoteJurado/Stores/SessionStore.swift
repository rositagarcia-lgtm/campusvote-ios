import Foundation
import Observation

enum JuryAccessType: String, CaseIterable, Identifiable {
    case external = "Externo"
    case internalStaff = "Interno"

    var id: Self { self }

    var subtitle: String {
        switch self {
        case .external:
            return "Ingresa con el correo y contraseña asignados a tu cuenta de jurado."
        case .internalStaff:
            return "Recibe un código en tu correo institucional para ingresar como docente."
        }
    }
}

@MainActor
@Observable
final class SessionStore {

    enum Phase: Equatable {
        case checking
        case signedOut
        case needsCode(tempToken: String)
        case mustChangePassword(User)
        case signedIn(User)
    }

    private(set) var phase: Phase = .checking
    private(set) var isWorking = false
    var errorMessage: String?
    private(set) var pendingEmail = ""
    private(set) var pendingAccessType: JuryAccessType?

    private let api: APIClient
    @ObservationIgnored private var sessionObserver: NSObjectProtocol?

    init(api: APIClient) {
        self.api = api
        sessionObserver = NotificationCenter.default.addObserver(
            forName: .campusVoteSessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.expireSession()
            }
        }
    }

    func restore() async {
        errorMessage = nil
        guard api.hasSavedSession else {
            api.clearTokens()
            SessionArchive.clear()
            InstitutionAppearance.reset()
            phase = .signedOut
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let user = try await api.send(.me, as: User.self)
            SessionArchive.save(user)
            try await validateAccess(for: user)
            if let organizationId = user.organizationId {
                await loadBrand(organizationId: organizationId)
            }
            phase = user.mustChangePassword ? .mustChangePassword(user) : .signedIn(user)
        } catch let error as APIError {
            if error.isSessionRejection {
                api.clearTokens()
                SessionArchive.clear()
                InstitutionAppearance.reset()
                errorMessage = error.userMessage
                phase = .signedOut
            } else {
                await restoreCachedSession(message: error.userMessage)
            }
        } catch {
            await restoreCachedSession(message: error.userMessage)
        }
    }

    /// Un fallo de red al abrir la app no debe borrar la sesión. Si ya hay un
    /// usuario guardado, entra con esos datos y deja que las pantallas
    /// reintenten sus propias peticiones.
    private func restoreCachedSession(message: String?) async {
        guard let cached = SessionArchive.load() else {
            errorMessage = message ?? APIError.network.message
            phase = .signedOut
            return
        }

        if let organizationId = cached.organizationId {
            await loadBrand(organizationId: organizationId)
        }
        errorMessage = message
        phase = cached.mustChangePassword ? .mustChangePassword(cached) : .signedIn(cached)
    }

    func login(email: String, password: String, accessType: JuryAccessType) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else {
            errorMessage = "Ingresa tu correo."
            return
        }
        guard accessType != .external || !password.isEmpty else {
            errorMessage = "Ingresa tu contraseña."
            return
        }

        pendingEmail = cleanEmail
        pendingAccessType = accessType
        await run {
            let endpoint: Endpoint = switch accessType {
            case .external:
                .login(email: cleanEmail, password: password)
            case .internalStaff:
                .requestEmailCode(email: cleanEmail)
            }
            let result = try await api.send(
                endpoint,
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
        guard case .needsCode(let tempToken) = phase else { return }
        await run {
            try await api.send(.resendEmailCode(tempToken: tempToken))
        }
    }

    func cancelCode() {
        errorMessage = nil
        pendingEmail = ""
        pendingAccessType = nil
        phase = .signedOut
    }

    func changePassword(current: String, new: String) async {
        guard case .mustChangePassword(var user) = phase else { return }
        await run {
            try await api.send(.changePassword(current: current, new: new))
            user.mustChangePassword = false
            SessionArchive.save(user)
            phase = .signedIn(user)
        }
    }

    func logout() async {
        try? await api.send(.logout(refreshToken: api.savedRefreshToken))
        api.clearTokens()
        SessionArchive.clear()
        InstitutionAppearance.reset()
        errorMessage = nil
        pendingEmail = ""
        pendingAccessType = nil
        phase = .signedOut
    }

    private func expireSession() {
        switch phase {
        case .signedIn, .mustChangePassword:
            break
        default:
            return
        }
        api.clearTokens()
        SessionArchive.clear()
        InstitutionAppearance.reset()
        pendingEmail = ""
        pendingAccessType = nil
        errorMessage = APIError.sessionExpired.message
        phase = .signedOut
    }

    private func finish(_ result: AuthResult) async throws {
        guard let token = result.token, let refreshToken = result.refreshToken else {
            throw APIError.decoding("La verificación no devolvió la sesión completa.")
        }
        guard var user = result.user else {
            throw APIError.decoding("La verificación no devolvió el usuario.")
        }
        guard user.canUseJuryApp else {
            throw APIError.server(
                status: 403,
                code: "FORBIDDEN",
                message: "Esta aplicación es solo para jurados y docentes asignados. Tu cuenta tiene el rol \(user.role)."
            )
        }
        guard let organizationId = user.organizationId, !organizationId.isEmpty else {
            throw APIError.decoding("La sesión no trae la institución del jurado.")
        }

        if result.mustChangePassword == true {
            user.mustChangePassword = true
        }

        do {
            try api.saveTokens(access: token, refresh: refreshToken)
            try await validateAccess(for: user)
        } catch {
            api.clearTokens()
            throw error
        }
        SessionArchive.save(user)
        await loadBrand(organizationId: organizationId)
        pendingEmail = ""
        pendingAccessType = nil
        phase = user.mustChangePassword ? .mustChangePassword(user) : .signedIn(user)
    }

    private func validateAccess(for user: User) async throws {
        guard user.canUseJuryApp else {
            throw APIError.server(
                status: 403,
                code: "FORBIDDEN",
                message: "Esta aplicación es solo para jurados y docentes asignados."
            )
        }
        let assignments = try await api.send(.myAssignments, as: [FairAssignment].self)
        guard !assignments.isEmpty else {
            throw APIError.server(
                status: 403,
                code: "NO_ASSIGNMENTS",
                message: "No tienes una feria asignada. Contacta al administrador."
            )
        }
    }

    private func loadBrand(organizationId: String) async {
        do {
            let brand = try await api.send(.organization(id: organizationId), as: OrganizationBrand.self)
            InstitutionAppearance.apply(brand)
        } catch {
            // Conserva la marca ya aplicada si el fallo es de red. Solo vuelve
            // al verde por defecto cuando todavía no hay identidad cargada.
            if InstitutionAppearance.name == nil {
                InstitutionAppearance.reset()
            }
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
