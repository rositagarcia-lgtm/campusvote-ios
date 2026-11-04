import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @State private var accessType: JuryAccessType = .external
    @Environment(\.locale) private var locale
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
                    LoginHeader(accessType: accessType, showContent: showContent)
                    LoginAccessTypeSelector(accessType: accessType, showContent: showContent) { type in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            accessType = type
                            password = ""
                            showPassword = false
                        }
                        session.errorMessage = nil
                        focus = .email
                    }
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

    private var credentialsCard: some View {
        VStack(spacing: 12) {
            PremiumFieldRow(
                icon: "envelope.fill",
                label: "CORREO ELECTRÓNICO",
                isFocused: focus == .email
            ) {
                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text("jurado@campusvote.edu.pe")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.appNeutral)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $email)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .tint(Color.campusGreen)
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
            }

            if accessType == .external {
                PremiumFieldRow(
                    icon: "lock.fill",
                    label: "CONTRASEÑA",
                    isFocused: focus == .password
                ) {
                    HStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            if password.isEmpty {
                                Text("••••••••")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.appNeutral)
                                    .allowsHitTesting(false)
                            }
                            Group {
                                if showPassword {
                                    TextField("", text: $password)
                                } else {
                                    SecureField("", text: $password)
                                }
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .tint(Color.campusGreen)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .focused($focus, equals: .password)
                            .onSubmit(submit)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { showPassword.toggle() }
                        } label: {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .font(.system(size: 16))
                                .foregroundStyle(focus == .password ? Color.campusGreen : Color.appNeutral)
                        }
                        .accessibilityLabel(L10n.tr(showPassword ? "Ocultar contraseña" : "Mostrar contraseña", locale: locale))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
    }

    private var submitButton: some View {
        Button(action: submit) {
            HStack(spacing: 10) {
                if session.isWorking {
                    ProgressView().tint(Color(light: 0xFFFFFF, dark: 0x0E1514))
                } else {
                    Text(L10n.tr(accessType == .external ? "Ingresar al Panel" : "Enviar código", locale: locale))
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right").font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(Color(light: 0xFFFFFF, dark: 0x0E1514))
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

    private func submit() {
        guard canSubmit else { return }
        focus = nil
        Task {
            await session.login(email: email, password: password, accessType: accessType)
        }
    }
}

#Preview {
    LoginView()
        .environment(SessionStore(api: .shared))
}
