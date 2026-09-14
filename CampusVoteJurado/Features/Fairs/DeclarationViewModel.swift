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
                Endpoint.getDeclaration(fairId: fairId),
                as: DeclarationResponse.self
            )
            if response.signed, let declaration = response.declaration {
                self.isToggled = true
                self.signedAtDate = declaration.signedAt
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
            let statementText = "Declaro formalmente no tener conflicto de interés académico ni personal para evaluar los proyectos asignados."
            let result = try await APIClient.shared.send(
                Endpoint.signDeclaration(
                    fairId: fairId,
                    statement: statementText
                ),
                as: Declaration.self
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
}