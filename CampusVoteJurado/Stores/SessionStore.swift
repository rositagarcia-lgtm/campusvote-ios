import Foundation
import Observation
@MainActor
@Observable
final class SessionStore {

    // MARK: - Phase

    enum Phase: Equatable {
        case checking
        case signedOut
        case needsCode(tempToken: String)
        case signedIn(User)
    }

    // MARK: - Estado

    private(set) var phase: Phase = .checking

    private(set) var isWorking = false

    var errorMessage: String?

    /// Correo introducido durante el login.
    /// Se muestra posteriormente en TotpView.
    private(set) var pendingEmail = ""

    private let api: APIClient

    // MARK: - Init

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Restaurar sesión

    func restore() async {

        errorMessage = nil

        guard api.hasSavedSession else {
            phase = .signedOut
            return
        }

        isWorking = true

        defer {
            isWorking = false
        }

        do {

            let user = try await api.send(
                .me,
                as: User.self
            )

            accept(user)

        } catch {

            api.clearTokens()
            phase = .signedOut
        }
    }

    // MARK: - Login

    func login(
        email: String,
        password: String
    ) async {

        let cleanEmail = email
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

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
                .login(
                    email: cleanEmail,
                    password: password
                ),
                as: AuthResult.self
            )

            if result.requiresTotp == true,
               let tempToken = result.tempToken {

                phase = .needsCode(
                    tempToken: tempToken
                )

            } else {

                try finish(result)
            }
        }
    }

    // MARK: - TOTP

    func verifyCode(
        _ code: String
    ) async {

        guard case .needsCode(let tempToken) = phase else {
            return
        }

        let cleanCode = code
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard cleanCode.count == 6 else {
            errorMessage = "El código debe tener 6 dígitos."
            return
        }

        await run {

            let result = try await api.send(
                .verifyTotp(
                    code: cleanCode,
                    tempToken: tempToken
                ),
                as: AuthResult.self
            )

            try finish(result)
        }
    }

    // MARK: - Código de respaldo

    func verifyBackupCode(
        _ backupCode: String
    ) async {

        guard case .needsCode(let tempToken) = phase else {
            return
        }

        let cleanCode = backupCode
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .uppercased()

        guard cleanCode.count == 8 else {
            errorMessage = "El código de respaldo debe tener 8 caracteres."
            return
        }

        await run {

            let result = try await api.send(
                .verifyBackupCode(
                    code: cleanCode,
                    tempToken: tempToken
                ),
                as: AuthResult.self
            )

            try finish(result)
        }
    }

    // MARK: - Cancelar 2FA

    func cancelCode() {

        errorMessage = nil
        pendingEmail = ""

        phase = .signedOut
    }

    // MARK: - Logout

    func logout() async {

        _ = try? await api.send(
            .logout(
                refreshToken: api.savedRefreshToken
            )
        )

        api.clearTokens()

        errorMessage = nil
        pendingEmail = ""

        phase = .signedOut
    }

    // MARK: - Finalizar login

    private func finish(
        _ result: AuthResult
    ) throws {

        guard
            let token = result.token,
            let user = result.user
        else {

            throw APIError.decoding(
                "La respuesta del inicio de sesión no contiene el token o el usuario."
            )
        }

        api.saveTokens(
            access: token,
            refresh: result.refreshToken
        )

        accept(user)
    }

    // MARK: - Validar usuario

    private func accept(
        _ user: User
    ) {

        guard user.isJury else {

            api.clearTokens()

            errorMessage =
                "Esta aplicación es solo para jurados. " +
                "Tu cuenta tiene el rol \(user.role)."

            phase = .signedOut

            return
        }

        errorMessage = nil
        phase = .signedIn(user)
    }

    // MARK: - Ejecutar petición

    private func run(
        _ work: () async throws -> Void
    ) async {

        isWorking = true
        errorMessage = nil

        defer {
            isWorking = false
        }

        do {

            try await work()

        } catch {

            errorMessage = error.userMessage
        }
    }
    func showLogin() {
        self.phase = .signedOut
    }
}
