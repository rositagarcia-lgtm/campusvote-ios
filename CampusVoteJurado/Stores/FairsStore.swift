import Foundation
import Observation

@Observable
@MainActor
final class FairsStore {
    private(set) var activeFairs: [FairAssignment] = []
    private(set) var closedFairs: [FairAssignment] = []
    /// Avance del jurado en cada feria activa, para la barra de la tarjeta.
    private(set) var progressByFair: [String: JuryProgress] = [:]
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    /// Institución del jurado, tal como la manda el backend en sus asignaciones.
    var organizationName: String? {
        (activeFairs + closedFairs).compactMap { $0.fair.organization?.name }.first
    }

    /// Sede de la feria activa (o de la última asignación que tenga una).
    var siteName: String? {
        (activeFairs + closedFairs)
            .compactMap { $0.fair.site }
            .map { $0.city?.isEmpty == false ? $0.city! : $0.name }
            .first
    }

    /// Hay al menos una feria abierta ahora mismo.
    var hasLiveFair: Bool {
        activeFairs.contains { $0.fair.status.uppercased() == "OPEN" }
    }
    
    /// ¿Ya firmó la declaración de conflicto de interés de esa feria?
       /// Sale del avance que ya se pidió al cargar la lista, así que no cuesta
       /// una llamada extra. Si el avance no llegó, se asume que no.
    func hasSignedDeclaration(fairId: String) -> Bool {
        progressByFair[fairId]?.declarationSigned ?? false
    }
    
    func fetchMyAssignments() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let assignments = try await api.send(.myAssignments, as: [FairAssignment].self)
            self.activeFairs = assignments.filter { $0.fair.status.uppercased() != "CLOSED" }
            self.closedFairs = assignments.filter { $0.fair.status.uppercased() == "CLOSED" }
            await fetchProgress()
        } catch {
            self.errorMessage = error.userMessage
        }
    }

    /// Cuántos proyectos tiene y cuántos lleva calificados en cada feria activa.
    /// Si una feria falla, se omite: la lista se muestra igual.
    private func fetchProgress() async {
        var resultado: [String: JuryProgress] = [:]
        for assignment in activeFairs {
            if let progress = try? await api.send(
                .myProgress(fairId: assignment.fair.id),
                as: JuryProgress.self
            ) {
                resultado[assignment.fair.id] = progress
            }
        }
        progressByFair = resultado
    }
}
