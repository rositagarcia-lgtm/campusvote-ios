import SwiftUI

/// Pantalla 01 · Acceso con correo y contraseña.
struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Correo", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                } footer: {
                    Text("Usa la cuenta de jurado que te dio la organización de la feria.")
                }

                if let message = session.errorMessage {
                    Section {
                        ErrorBanner(message: message)
                    }
                }

                Section {
                    Button {
                        Task { await session.login(email: email, password: password) }
                    } label: {
                        if session.isWorking {
                            ProgressView()
                        } else {
                            Text("Iniciar sesión")
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || session.isWorking)
                }
            }
            .navigationTitle("CampusVote Jurado")
        }
    }
}
