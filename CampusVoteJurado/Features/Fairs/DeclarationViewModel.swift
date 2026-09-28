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
    var statementText: String = DeclarationViewModel.statement
    var jurorName: String
    var institutionalId: String?

    init(
        fairId: String,
        jurorName: String = "Jurado calificador"
    ) {
        self.fairId = fairId
        self.jurorName = jurorName
    }

    @MainActor
    func fetchDeclarationStatus() async {
        isSigning = false
        errorMessage = nil

        await loadIdentity()

        do {
            let response = try await APIClient.shared.send(
                Endpoint.declaration(fairId: fairId),
                as: DeclarationResponse.self
            )
            if let text = response.serverStatement {
                statementText = text
            }
            if response.signed {
                self.isToggled = true
                self.signedAtDate = fechaLegible(response.declaration?.signedAt) ?? "Firmada"
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
            let result = try await APIClient.shared.send(
                Endpoint.signDeclaration(
                    fairId: fairId,
                    statement: statementText
                ),
                as: DeclarationAck.self
            )
            self.isSigning = false
            self.signedAtDate = fechaLegible(result.signedAt) ?? Date().formatted(date: .abbreviated, time: .shortened)
            self.navigateToProjects = true
            return true
        } catch {
            self.isSigning = false
            self.errorMessage = error.userMessage
            return false
        }
    }

    @MainActor
    private func loadIdentity() async {
        guard let me = try? await APIClient.shared.send(
            Endpoint(path: "users/me", method: "GET"),
            as: JuryIdentity.self
        ) else { return }

        let name = [me.firstName, me.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if !name.isEmpty {
            jurorName = name
        }
        let code = me.institutionalId?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let code, !code.isEmpty {
            institutionalId = code
        }
    }

    private func fechaLegible(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let withMillis = ISO8601DateFormatter()
        withMillis.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        guard let date = withMillis.date(from: raw) ?? plain.date(from: raw) else { return raw }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    static let statement = """
    Declaro no tener conflicto de interés para evaluar los proyectos de esta feria: \
    no tengo parentesco con los expositores, no fui su asesor ni integrante de ningún equipo, \
    y me comprometo a calificar con imparcialidad.
    """
}

private struct JuryIdentity: Decodable {
    let firstName: String?
    let lastName: String?
    let institutionalId: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case institutionalId = "institutional_id"
    }
}
