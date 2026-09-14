import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showHelp = false
    @FocusState private var focus: Field?

    private enum Field {
        case email
        case password
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        !session.isWorking
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header
                credentialsCard

                if let message = session.errorMessage {
                    ErrorBanner(message: message)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                submitButton
                twoStepNote

                helpLink
                    .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
        .alert("¿Problemas para acceder?", isPresented: $showHelp) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Escribe al administrador de la feria en tu institución: él crea las cuentas de jurado y puede restablecer tu acceso.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {

            Label(
                "TECSUP · SISTEMA ELECTORAL UNIVERSITARIO",
                systemImage: "checkmark.seal"
            )
            .font(.system(size: 10, weight: .medium))
            .tracking(1)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.iconTile)
            )

            VStack(spacing: 4) {
                Image("logo_campusvote")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
    }

    // MARK: - Credenciales

    private var credentialsCard: some View {
        VStack(spacing: 0) {

            FieldRow(
                icon: "envelope",
                label: "CORREO INSTITUCIONAL"
            ) {

                TextField(
                    text: $email,
                    prompt: Text(verbatim: "jurado@tecsup.edu.pe")
                        .foregroundStyle(Color.gray.opacity(0.35))
                ) {
                    Text("")
                }
                .font(.system(size: 15))
                .foregroundStyle(Color.gray.opacity(0.8))
                .tint(Color.brand)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focus, equals: .email)
                .onSubmit {
                    focus = .password
                }
            }

            Divider()
                .padding(.leading, 76)

            FieldRow(
                icon: "lock",
                label: "CONTRASEÑA"
            ) {

                HStack {

                    Group {
                        if showPassword {
                            TextField("••••••••", text: $password)
                        } else {
                            SecureField("••••••••", text: $password)
                        }
                    }
                    .font(.system(size: 15))
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($focus, equals: .password)
                    .onSubmit(submit)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(
                            systemName: showPassword
                            ? "eye"
                            : "eye.slash"
                        )
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(
                        showPassword
                        ? "Ocultar contraseña"
                        : "Mostrar contraseña"
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 12,
            y: 4
        )
    }

    // MARK: - Botón ingresar

    private var submitButton: some View {
        Button(action: submit) {

            HStack(spacing: 10) {

                if session.isWorking {

                    ProgressView()
                        .tint(Color.onBrand)

                } else {

                    Text("Ingresar")

                    Image(systemName: "arrow.right")
                }
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.onBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brand)
            )
        }
        .disabled(!canSubmit)
        .opacity(
            canSubmit || session.isWorking
            ? 1
            : 0.6
        )
    }

    // MARK: - Verificación en dos pasos

    private var twoStepNote: some View {
        HStack(alignment: .top, spacing: 12) {

            Image(systemName: "lock.shield")
                .font(.system(size: 15))
                .foregroundStyle(Color.brandGold)

            Text(
                "Si tu cuenta tiene verificación en dos pasos, " +
                "te pediremos el código de 6 dígitos en el siguiente paso."
            )
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Ayuda

    private var helpLink: some View {
        Button {
            showHelp = true
        } label: {

            Label(
                "¿Problemas para acceder? Contactar a soporte electoral Tecsup",
                systemImage: "questionmark.circle"
            )
            .font(.system(size: 12))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.brandTeal)
        }
    }

    // MARK: - Login

    private func submit() {
        guard canSubmit else {
            return
        }

        focus = nil

        Task {
            await session.login(
                email: email,
                password: password
            )
        }
    }
}

// MARK: - Fila de campos

private struct FieldRow<Content: View>: View {

    let icon: String
    let label: String

    @ViewBuilder
    let content: Content

    var body: some View {

        HStack(spacing: 16) {

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.brand)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.iconTile)
                )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(label)
                    .font(
                        .caption.weight(.semibold)
                    )
                    .tracking(0.8)
                    .foregroundStyle(.secondary)

                content
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

#Preview("Acceso") {
    LoginView()
        .environment(
            SessionStore(api: .shared)
        )
}
