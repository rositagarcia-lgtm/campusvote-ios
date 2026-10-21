import Foundation

extension SessionStore {
    func finish(_ result: AuthResult) async throws {
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
                message: L10n.format(
                    "Esta aplicación es solo para jurados y docentes asignados. Tu cuenta tiene el rol %@.",
                    locale: Locale(identifier: UserDefaults.standard.string(forKey: "campusvote.preferences.language") ?? "es"),
                    user.role
                )
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

    func validateAccess(for user: User) async throws {
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

    func loadBrand(organizationId: String) async {
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

    func run(_ work: () async throws -> Void) async {
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
