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
        await loadBrand(user: user, replacing: true)
        guard api.hasSavedSession else { throw APIError.sessionExpired }
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
        let assignments = try await api.sendPage(.myAssignments, as: FairAssignment.self)
        guard !assignments.items.isEmpty else {
            throw APIError.server(
                status: 403,
                code: "NO_ASSIGNMENTS",
                message: "No tienes una feria asignada. Contacta al administrador."
            )
        }
    }

    /// Vuelve a pedir los colores de la IE sin borrar los que ya se ven.
    /// Si la red falla, la marca en pantalla se queda.
    func refreshBrand() async {
        let user: User
        switch phase {
        case .signedIn(let current), .mustChangePassword(let current):
            user = current
        default:
            return
        }
        await loadBrand(user: user, replacing: false)
    }

    func loadBrand(user: User, replacing: Bool) async {
        let loadID = UUID()
        brandLoadID = loadID
        let generation = sessionGeneration
        if replacing {
            InstitutionAppearance.reset()
            guard brandLoadID == loadID, sessionGeneration == generation else { return }
        }
        guard let organizationId = user.organizationId, !organizationId.isEmpty else { return }
        if replacing, let cached = BrandArchive.load(user: user) {
            guard brandLoadID == loadID, sessionGeneration == generation else { return }
            InstitutionAppearance.apply(cached)
        }
        do {
            let brand = try await api.send(.organization(id: organizationId), as: OrganizationBrand.self)
            guard brandLoadID == loadID, sessionGeneration == generation else { return }
            BrandArchive.save(brand, user: user)
            InstitutionAppearance.apply(brand)
        } catch {
            guard brandLoadID == loadID, sessionGeneration == generation else { return }
            if replacing {
                BrandArchive.clear(user: user)
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
