import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @State private var accessType: JuryAccessType = .external
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showHelp = false
    @FocusState private var focus: Field?
    @State private var showContent = false

    private enum Field {
        case email
        case password
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        (accessType == .internalStaff || !password.isEmpty) &&
        !session.isWorking
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 28) {
                    header
                    accessTypeSelector
                    credentialsCard

                    if let message = session.errorMessage {
                        ErrorBanner(message: message)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                    }

                    submitButton
                    twoStepNote
                    helpLink
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height, alignment: .center)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground.ignoresSafeArea())
        }
        .alert("¿Problemas para acceder?", isPresented: $showHelp) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Escribe al administrador de la feria en tu institución: él crea las cuentas de jurado y puede restablecer tu acceso.")
        }
        .task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 16) {
            Image("logo_campusvote")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1.0 : 0.9)
                .blur(radius: showContent ? 0 : 8)
            
            Text(accessType.subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.campusGreen.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
        }
    }

    // MARK: - Tipo de acceso
    private var accessTypeSelector: some View {
        HStack(spacing: 8) {
            ForEach(JuryAccessType.allCases) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        accessType = type
                        password = ""
                        showPassword = false
                    }
                    session.errorMessage = nil
                    focus = .email
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: type == .external ? "person.badge.key.fill" : "building.columns.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(type.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(accessType == type ? Color.onBrand : Color.campusGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Group {
                            if accessType == type {
                                LinearGradient(
                                    colors: [Color.campusGreen, Color.campusTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.cardBackground
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Color.campusGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
    }

    // MARK: - Tarjeta de Credenciales
    private var credentialsCard: some View {
        VStack(spacing: 0) {
            PremiumFieldRow(
                icon: "envelope.fill",
                label: "CORREO ELECTRÓNICO",
                isFocused: focus == .email
            ) {
                TextField("jurado@campusvote.edu.pe", text: $email)
                    .font(.system(size: 15, weight: .medium))
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focus, equals: .email)
                    .onSubmit {
                        if accessType == .external {
                            focus = .password
                        } else {
                            submit()
                        }
                    }
            }

            if accessType == .external {
                Rectangle()
                    .fill(Color.campusGreen.opacity(0.1))
                    .frame(height: 1)
                    .padding(.leading, 60)

                PremiumFieldRow(
                    icon: "lock.fill",
                    label: "CONTRASEÑA",
                    isFocused: focus == .password
                ) {
                    HStack {
                        Group {
                            if showPassword {
                                TextField("••••••••", text: $password)
                            } else {
                                SecureField("••••••••", text: $password)
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .focused($focus, equals: .password)
                        .onSubmit(submit)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { showPassword.toggle() }
                        } label: {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .font(.system(size: 16))
                                .foregroundStyle(focus == .password ? Color.campusGreen : Color.appNeutral)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.campusGreen.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.campusGreen.opacity(0.08), radius: 20, x: 0, y: 8)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
    }

    // MARK: - Botón de Envío
    private var submitButton: some View {
        Button(action: submit) {
            HStack(spacing: 10) {
                if session.isWorking {
                    ProgressView().tint(Color.onBrand)
                } else {
                    Text(accessType == .external ? "Ingresar al Panel" : "Enviar código")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right").font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(Color.onBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Group {
                    if canSubmit {
                        LinearGradient(colors: [Color.campusGreen, Color.campusTeal], startPoint: .leading, endPoint: .trailing)
                    } else {
                        Color.campusGreen.opacity(0.3)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.campusGreen.opacity(canSubmit ? 0.3 : 0.0), radius: 12, y: 6)
        }
        .disabled(!canSubmit || session.isWorking)
        .scaleEffect(canSubmit && !session.isWorking ? 1.0 : 0.98)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
        .animation(.easeInOut(duration: 0.2), value: canSubmit)
    }

    // MARK: - Nota de Verificación
    private var twoStepNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 16))
                .foregroundStyle(Color.brandGold)
                .frame(width: 24, height: 24)
                .background(Color.brandGold.opacity(0.15))
                .clipShape(Circle())

            Text("Te enviaremos un código de 6 dígitos a tu correo. Caduca en 10 minutos.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.appNeutral)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Enlace de Ayuda
    private var helpLink: some View {
        Button { showHelp = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle.fill").font(.system(size: 13))
                Text("¿Problemas para acceder? Contactar a soporte").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.campusTeal)
        }
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Lógica de Submit
    private func submit() {
        guard canSubmit else { return }
        focus = nil
        Task {
            await session.login(email: email, password: password, accessType: accessType)
        }
    }
}

// MARK: - Componente de Campo Premium
private struct PremiumFieldRow<Content: View>: View {
    let icon: String
    let label: String
    let isFocused: Bool
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isFocused ? Color.onBrand : Color.campusGreen.opacity(0.6))
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(isFocused ? Color.campusGreen : Color.iconTile)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(isFocused ? Color.campusGreen : Color.appNeutral)
                
                content.foregroundStyle(Color.campusGreen)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? Color.campusGreen : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environment(SessionStore(api: .shared))
}
