import SwiftUI

/// Segundo paso del acceso, solo si la cuenta tiene verificación en dos pasos.
struct TotpView: View {
    @Environment(SessionStore.self) private var session
    @State private var code = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Código de 6 dígitos", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                } footer: {
                    Text("Escribe el código que muestra tu app autenticadora.")
                }

                if let message = session.errorMessage {
                    Section {
                        ErrorBanner(message: message)
                    }
                }

                Section {
                    Button("Verificar") {
                        Task { await session.verifyCode(code) }
                    }
                    .disabled(code.count != 6 || session.isWorking)

                    Button("Volver al inicio de sesión", role: .cancel) {
                        session.cancelCode()
                    }
                }
            }
            .navigationTitle("Verificación")
        }
    }
}
