import SwiftUI

/// Pantalla 03 · Declaración de imparcialidad. Sin ella, el backend no deja evaluar.
struct DeclarationView: View {
    let fair: Fair
    @Environment(FairsStore.self) private var fairs
    @Environment(\.dismiss) private var dismiss
    @State private var accepted = false
    @State private var isSending = false

    private let statement =
        "Declaro no tener conflicto de interés con los proyectos de esta feria y evaluar con imparcialidad."

    var body: some View {
        NavigationStack {
            Form {
                Section("Declaración de imparcialidad") {
                    Text(statement)
                    Toggle("Acepto la declaración", isOn: $accepted)
                }

                if let message = fairs.errorMessage {
                    Section {
                        ErrorBanner(message: message)
                    }
                }
            }
            .navigationTitle(fair.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Firmar") {
                        Task {
                            isSending = true
                            if await fairs.sign(fair: fair, statement: statement) {
                                dismiss()
                            }
                            isSending = false
                        }
                    }
                    .disabled(!accepted || isSending)
                }
            }
        }
    }
}
