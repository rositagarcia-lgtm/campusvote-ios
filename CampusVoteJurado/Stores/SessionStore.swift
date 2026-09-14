import Foundation
import Observation

/// Estado de la sesión: quién entró y en qué paso del inicio de sesión está.
@Observable
@MainActor
final class SessionStore {
    enum Phase: Equatable {
        /// Al abrir la app, revisando si hay una sesión guardada.
        case checking
        case signedOut
        /// La cuenta tiene 2FA: falta el código de 6 dígitos.
        case needsCode(tempToken: String)
        case signedIn(User)
    }

    private(set) var phase: Phase = .checking
    private(set) var isWorking = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    /// Si hay un token guardado, confirma con el backend que sigue vigente.
    func restore() async {
        guard api.hasSavedSession else {
            phase = .signedOut
            return
        }
        do {
            let user = try await api.send(.me, as: User.self)
            accept(user)
        } catch {
            api.clearTokens()
            phase = .signedOut
        }
    }

    func login(email: String, password: String) async {
        await run {
            let result = try await api.send(
                .login(email: email.trimmingCharacters(in: .whitespaces), password: password),
                as: AuthResult.self
            )
            if result.requiresTotp == true, let tempToken = result.tempToken {
                phase = .needsCode(tempToken: tempToken)
            } else {
                try finish(result)
            }
        }
    }

    func verifyCode(_ code: String) async {
        guard case .needsCode(let tempToken) = phase else { return }
        await run {
            let result = try await api.send(.verifyTotp(code: code, tempToken: tempToken), as: AuthResult.self)
            try finish(result)
        }
    }

    func cancelCode() {
        errorMessage = nil
        phase = .signedOut
    }

    func logout() async {
        // Se avisa al backend para anular el refresh token; si falla, igual se cierra aquí.
        _ = try? await api.send(.logout(refreshToken: api.savedRefreshToken))
        api.clearTokens()
        phase = .signedOut
    }

    private func finish(_ result: AuthResult) throws {
        guard let token = result.token, let user = result.user else {
            throw APIError.decoding("La respuesta del inicio de sesión no trae el token")
        }
        api.saveTokens(access: token, refresh: result.refreshToken)
        accept(user)
    }

    /// Esta app es solo para jurados: cualquier otro rol se rechaza aquí.
    private func accept(_ user: User) {
        guard user.isJury else {
            api.clearTokens()
            errorMessage = "Esta app es solo para jurados. Tu cuenta tiene el rol \(user.role)."
            phase = .signedOut
            return
        }
        phase = .signedIn(user)
    }

    /// Marca el trabajo en curso y convierte cualquier error en un mensaje.
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
