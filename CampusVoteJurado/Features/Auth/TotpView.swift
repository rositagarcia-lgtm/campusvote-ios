import SwiftUI

struct TotpView: View {
    @Environment(SessionStore.self) private var session
    @State private var code = ""
    @State private var sentAt = Date()
    @State private var didResend = false

    private let lifetime: TimeInterval = 10 * 60

    private var canVerify: Bool {
        !session.isWorking && code.count == 6
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Código de correo")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text("Escribe el código de 6 dígitos que enviamos a \(session.pendingEmail).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    CodeInputView(code: $code)
                    expiry

                    if didResend {
                        Text("Enviamos un código nuevo.")
                            .font(.footnote)
                            .foregroundStyle(Color.campusTeal)
                    }

                    if let message = session.errorMessage {
                        ErrorBanner(message: message)
                    }

                    verifyButton

                    Button("Reenviar código") {
                        Task {
                            await session.resendCode()
                            if session.errorMessage == nil {
                                sentAt = Date()
                                code = ""
                                didResend = true
                            }
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.campusTeal)
                    .disabled(session.isWorking)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onChange(of: code) { _, nuevo in
            if nuevo.count == 6 {
                verify()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                session.cancelCode()
            } label: {
                Label("Volver al inicio", systemImage: "chevron.left")
                    .font(.subheadline)
                    .foregroundStyle(Color.campusGreen)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var expiry: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(lifetime - context.date.timeIntervalSince(sentAt)))
            let minutes = remaining / 60
            let seconds = remaining % 60
            Text(remaining == 0
                 ? "El código caducó. Pide otro."
                 : String(format: "Caduca en %d:%02d", minutes, seconds))
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var verifyButton: some View {
        Button(action: verify) {
            Group {
                if session.isWorking {
                    ProgressView().tint(Color.onBrand)
                } else {
                    Text("Verificar")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.onBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.campusGreen))
        }
        .disabled(!canVerify)
        .opacity(canVerify || session.isWorking ? 1 : 0.6)
    }

    private func verify() {
        guard canVerify else { return }
        Task {
            await session.verifyCode(code)
            if session.errorMessage != nil {
                code = ""
            }
        }
    }
}

