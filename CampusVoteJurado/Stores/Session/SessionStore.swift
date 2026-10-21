import Foundation
import Observation

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

    var phase: Phase = .checking
    var isWorking = false
    var errorMessage: String?
    var pendingEmail = ""
    var pendingAccessType: JuryAccessType?

    let api: APIClient
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
}
