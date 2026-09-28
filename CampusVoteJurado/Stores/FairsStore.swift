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

    /// Institución del jurado. Si la marca ya cargó, ese nombre manda.
    var organizationName: String? {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return (activeFairs + closedFairs).compactMap { $0.fair.organizationName }.first
    }

    /// Una sola sede para el encabezado. Si hay varias, cada feria trae la suya.
    var siteName: String? {
        let names = Set((activeFairs + closedFairs).compactMap { $0.fair.siteName })
        guard names.count == 1 else { return nil }
        return names.first
    }

    /// Hay al menos una feria abierta ahora mismo.
    var hasLiveFair: Bool {
        activeFairs.contains { $0.fair.isOpen }
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
