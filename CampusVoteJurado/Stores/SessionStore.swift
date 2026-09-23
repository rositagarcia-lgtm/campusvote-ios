import Foundation
import Observation
@MainActor
@Observable
final class SessionStore {

    // MARK: - Phase

    enum Phase: Equatable {
        case checking
        case signedOut
        /// Primer acceso: la cuenta aún no tiene autenticador, toca el QR.
        case needsSetup(tempToken: String)
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

    /// QR y secreto mientras se configura el autenticador.
    private(set) var setup: TotpSetup?

    /// Códigos de respaldo recién generados. El backend los muestra una vez.
    private(set) var backupCodes: [String] = []

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

            if result.requiresOnboarding == true,
               let tempToken = result.tempToken {

                setup = nil
                backupCodes = []

                phase = .needsSetup(
                    tempToken: tempToken
                )

            } else if result.requiresTotp == true,
                      let tempToken = result.tempToken {

                phase = .needsCode(
                    tempToken: tempToken
                )

            } else {

                try finish(result)
            }
        }
    }

    // MARK: - Primer acceso (QR)

    /// Pide el QR al backend. Solo la primera vez: una vez activado el 2FA,
    /// el backend ya no vuelve a entregarlo.
    func loadSetup() async {

        guard case .needsSetup(let tempToken) = phase, setup == nil else {
            return
        }

        await run {

            setup = try await api.send(
                .totpSetup(
                    tempToken: tempToken
                ),
                as: TotpSetup.self
            )
        }
    }

    /// Primer código del autenticador: activa el 2FA y guarda los códigos
    /// de respaldo para mostrarlos.
    func confirmSetup(
        _ code: String
    ) async {

        guard case .needsSetup(let tempToken) = phase else {
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

            let enabled = try await api.send(
                .totpConfirm(
                    code: cleanCode,
                    tempToken: tempToken
                ),
                as: TotpEnabled.self
            )

            backupCodes = enabled.backupCodes
        }
    }

    /// Cierra el primer acceso y entrega la sesión definitiva.
    func finishSetup() async {

        guard case .needsSetup(let tempToken) = phase else {
            return
        }

        await run {

            let result = try await api.send(
                .totpFinalize(
                    tempToken: tempToken
                ),
                as: AuthResult.self
            )

            try finish(result)
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
        setup = nil
        backupCodes = []

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
        setup = nil
        backupCodes = []

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

        setup = nil
        backupCodes = []

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
