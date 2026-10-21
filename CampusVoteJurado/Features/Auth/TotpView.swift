import SwiftUI

struct TotpView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.locale) private var locale
    @State private var code = ""
    @State private var sentAt = Date()
    @State private var didResend = false
    @State private var isVerifying = false
    @State private var showContent = false

    private let lifetime: TimeInterval = 10 * 60

    private var canVerify: Bool {
        !session.isWorking && !isVerifying && code.count == 6
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(spacing: 28) {
                    // MARK: - Header
                    headerView

                    // MARK: - Input de Código
                    CodeInputView(code: $code, length: 6, onComplete: verify)

                    // MARK: - Temporizador
                    expiryTimer

                    // MARK: - Mensajes de Estado y Error
                    VStack(spacing: 16) {
                        if didResend {
                            resendSuccessMessage
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if let message = session.errorMessage {
                            ErrorBanner(message: message)
                                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                        }
                    }

                    // MARK: - Acciones
                    VStack(spacing: 16) {
                        verifyButton
                        resendButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showContent = true
                }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                session.cancelCode()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Volver")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.campusGreen)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: showContent)
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.badge.checkmark.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.campusGreen.opacity(0.8))
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1.0 : 0.8)
            
            Text("Código de verificación")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.campusGreen)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

            Text(L10n.format("Escribe el código de 6 dígitos que enviamos a %@.", locale: locale, session.pendingEmail))
                .font(.subheadline)
                .foregroundStyle(Color.appNeutral)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
        }
        .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)
    }

    // MARK: - Temporizador Premium
    private var expiryTimer: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(lifetime - context.date.timeIntervalSince(sentAt)))
            let minutes = remaining / 60
            let seconds = remaining % 60
            let isExpiring = remaining > 0 && remaining < 60 // Alerta visual en el último minuto

            HStack(spacing: 8) {
                Image(systemName: isExpiring ? "exclamationmark.circle.fill" : "clock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isExpiring ? .red : Color.campusTeal)
                
                Text(remaining == 0
                     ? L10n.tr("Código caducado", locale: locale)
                     : L10n.format("%d:%02d restantes", locale: locale, minutes, seconds))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isExpiring ? .red : Color.campusTeal)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background((isExpiring ? Color.red : Color.campusTeal).opacity(0.1))
            .clipShape(Capsule())
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
        }
    }

    // MARK: - Mensaje de Reenvío Exitoso
    private var resendSuccessMessage: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.campusTeal)
            Text("Código nuevo enviado correctamente")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.campusTeal)
        }
    }

    // MARK: - Botón de Verificación
    private var verifyButton: some View {
        Button(action: verify) {
            HStack(spacing: 8) {
                if session.isWorking || isVerifying {
                    ProgressView().tint(Color.onBrand)
                } else {
                    Text("Verificar código").fontWeight(.semibold)
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .foregroundStyle(Color.onBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Group {
                    if canVerify {
                        LinearGradient(colors: [Color.campusGreen, Color.campusTeal], startPoint: .leading, endPoint: .trailing)
                    } else {
                        Color.campusGreen.opacity(0.3)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.campusGreen.opacity(canVerify ? 0.3 : 0.0), radius: 12, y: 6)
        }
        .disabled(!canVerify || session.isWorking || isVerifying)
        .scaleEffect(canVerify ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: canVerify)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
    }

    // MARK: - Botón de Reenvío
    private var resendButton: some View {
        Button {
            Task {
                await session.resendCode()
                if session.errorMessage == nil {
                    withAnimation {
                        sentAt = Date()
                        code = ""
                        didResend = true
                    }
                }
            }
        } label: {
            Text("¿No lo recibiste? Reenviar código")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.campusGreen)
        }
        .disabled(session.isWorking || isVerifying)
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
    }

    // MARK: - Lógica de Verificación
    private func verify() {
        guard canVerify else { return }
        let current = code
        isVerifying = true
        
        Task {
            await session.verifyCode(current)
            isVerifying = false
            
            if session.errorMessage != nil {
                withAnimation { code = "" }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TotpView()
}

