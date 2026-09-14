import Foundation
import Observation

/// Ferias asignadas al jurado y su declaración de imparcialidad.
@Observable
@MainActor
final class FairsStore {
    private(set) var fairs: [Fair] = []
    private(set) var isLoading = false
    var errorMessage: String?

    /// Declaración firmada por feria: id de la feria → firmada o no.
    private(set) var signed: [String: Bool] = [:]

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let assignments = try await api.send(.myAssignments, as: [Assignment].self)
            fairs = assignments.map(\.fair)
        } catch {
            errorMessage = error.userMessage
        }
    }

    func loadDeclaration(for fair: Fair) async {
        do {
            let status = try await api.send(.declaration(fairId: fair.id), as: DeclarationStatus.self)
            signed[fair.id] = status.signed
        } catch {
            errorMessage = error.userMessage
        }
    }

    /// Firma la declaración. Devuelve true si quedó firmada.
    func sign(fair: Fair, statement: String) async -> Bool {
        errorMessage = nil
        do {
            _ = try await api.send(.signDeclaration(fairId: fair.id, statement: statement), as: Declaration.self)
            signed[fair.id] = true
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}
