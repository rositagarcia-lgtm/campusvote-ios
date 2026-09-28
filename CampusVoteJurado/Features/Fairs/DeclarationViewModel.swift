import SwiftUI
import Observation

@Observable
final class DeclarationViewModel {
    let fairId: String
    var isToggled: Bool = false
    var signedAtDate: String? = nil
    var isSigning: Bool = false
    var navigateToProjects: Bool = false
    var errorMessage: String? = nil

    var jurorName: String
    var jurorRole: String

    init(
        fairId: String,
        jurorName: String = "Jurado Calificador",
        jurorRole: String = "Jurado Calificador"
    ) {
        self.fairId = fairId
        self.jurorName = jurorName
        self.jurorRole = jurorRole
    }

    @MainActor
    func fetchDeclarationStatus() async {
        isSigning = false
        errorMessage = nil

        do {
            let response = try await APIClient.shared.send(
                Endpoint.declaration(fairId: fairId),
                as: DeclarationResponse.self
            )
            if response.signed {
                self.isToggled = true
                self.signedAtDate = response.declaration?.signedAt ?? "Firmada"
                self.navigateToProjects = true
            }
        } catch {
            self.errorMessage = error.userMessage
        }
    }

    @MainActor
    func submitDeclaration() async -> Bool {
        if signedAtDate != nil {
            self.navigateToProjects = true
            return true
        }

        isSigning = true
        errorMessage = nil

        do {
            let statementText = Self.statement
            let result = try await APIClient.shared.send(
                Endpoint.signDeclaration(
                    fairId: fairId,
                    statement: statementText
                ),
                as: DeclarationAck.self
            )
            self.isSigning = false
            self.signedAtDate = result.signedAt ?? Date().formatted(date: .long, time: .shortened)
            self.navigateToProjects = true
            return true
        } catch {
            self.isSigning = false
            self.errorMessage = error.userMessage
            return false
        }
    }

    static let statement = """
    Declaro no tener conflicto de interés para evaluar los proyectos de esta feria: \
    no tengo parentesco con los expositores, no fui su asesor ni integrante de ningún equipo, \
    y me comprometo a calificar con imparcialidad.
    """
}