import SwiftUI

/// código de 6 dígitos de la app
/// autenticadora o, si no la tiene a mano, un código de respaldo de 8 caracteres.
struct TotpView: View {
    @Environment(SessionStore.self) private var session
    @State private var code = ""
    @State private var backupCode = ""
    @State private var usingBackup = false

    private var canVerify: Bool {
        !session.isWorking && (usingBackup ? backupCode.count == 8 : code.count == 6)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(spacing: 20) {
                    badge

                    VStack(spacing: 8) {
                        Text("Verificación en dos pasos")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text(subtitle)
                            .font(.footnote.italic())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .frame(maxWidth: .infinity)

                    if usingBackup {
                        backupField
                    } else {
                        CodeInputView(code: $code)
                        ExpiryPill()
                    }

                    accountCard

                    if let message = session.errorMessage {
                        ErrorBanner(message: message)
                            .frame(maxWidth: .infinity)
                    }

                    verifyButton

                    Button(usingBackup ? "Usar el código de 6 dígitos" : "Usar un código de respaldo") {
                        usingBackup.toggle()
                        session.errorMessage = nil
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandTeal)

                    Label("Código válido por 30 segundos", systemImage: "lock")
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onChange(of: code) { _, nuevo in
            // Con el sexto dígito se verifica sola.
            if nuevo.count == 6 {
                verify()
            }
        }
    }

    private var subtitle: String {
        usingBackup
            ? "Escribe uno de tus códigos de respaldo de 8 caracteres. Cada código sirve una sola vez."
            : "Escribe el código de 6 dígitos de tu app autenticadora (Google o Microsoft Authenticator)"
    }

    // MARK: - Partes de la pantalla

    private var topBar: some View {
        HStack {
            Button {
                session.cancelCode()
            } label: {
                Label("Volver al inicio", systemImage: "chevron.left")
                    .font(.subheadline)
                    .foregroundStyle(Color.brand)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var badge: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(Color.brandMint)
                    .frame(width: 130, height: 130)
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 92, height: 92)
                Image(systemName: "lock.shield")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Color.brand)
            }

            Image(systemName: "checkmark.seal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.brand)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.brandGold.opacity(0.45)))
                .offset(x: -14, y: -14)
        }
        .padding(.top, 12)
        .accessibilityHidden(true)
    }

    private var backupField: some View {
        TextField("ABCD2345", text: $backupCode)
            .font(.system(size: 22, weight: .semibold, design: .monospaced))
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.iconTile))
            .onChange(of: backupCode) { _, nuevo in
                // Solo letras y números, como máximo 8.
                let limpio = String(nuevo.filter { $0.isLetter || $0.isNumber }.prefix(8))
                if limpio != nuevo {
                    backupCode = limpio
                }
            }
    }

    /// Tarjeta de la cuenta que está entrando. En este paso el backend todavía no
    /// devuelve el perfil, así que se muestra el correo con el que inició sesión.
    private var accountCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.title3)
                .foregroundStyle(Color.brand)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.iconTile))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Jurado de feria")
                        .font(.subheadline.weight(.semibold))
                    Text("2FA")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.brandMint))
                        .foregroundStyle(Color.brand)
                }
                Text(session.pendingEmail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            Image(systemName: "lock")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
    }

    private var verifyButton: some View {
        Button(action: verify) {
            Group {
                if session.isWorking {
                    ProgressView()
                        .tint(Color.onBrand)
                } else {
                    Text("Verificar")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.onBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.brand))
        }
        .disabled(!canVerify)
        .opacity(canVerify || session.isWorking ? 1 : 0.6)
    }

    private func verify() {
        guard canVerify else { return }
        Task {
            if usingBackup {
                await session.verifyBackupCode(backupCode)
            } else {
                await session.verifyCode(code)
                // Si el código era incorrecto, se limpia para escribir el siguiente.
                if session.errorMessage != nil {
                    code = ""
                }
            }
        }
    }
}

/// Cuenta regresiva del código actual. Los códigos cambian cada 30 segundos,
/// alineados al reloj, igual que en Google o Microsoft Authenticator.
private struct ExpiryPill: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = 30 - Int(context.date.timeIntervalSince1970) % 30

            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .font(.footnote)
                    .foregroundStyle(Color.brandTeal)
                (Text("Expira en ") + Text("\(remaining)s").bold())
                    .font(.footnote)
                    .monospacedDigit()
                ProgressView(value: Double(remaining), total: 30)
                    .tint(Color.brandTeal)
                    .frame(width: 80)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.iconTile))
        }
    }
}

#Preview("Verificación en dos pasos") {
    TotpView()
        .environment(SessionStore(api: .shared))
}
