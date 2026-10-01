import SwiftUI

struct ChangePasswordView: View {
    @Environment(SessionStore.self) private var session
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @FocusState private var focus: Field?

    private enum Field {
        case current, new, confirm
    }

    private var rules: [(ok: Bool, text: String)] {
        [
            ((8...72).contains(newPassword.count), "Entre 8 y 72 caracteres"),
            (newPassword.contains(where: \.isLowercase), "Una minúscula"),
            (newPassword.contains(where: \.isUppercase), "Una mayúscula"),
            (newPassword.contains(where: \.isNumber), "Un número"),
            (newPassword.contains { !$0.isLetter && !$0.isNumber }, "Un carácter especial"),
            (!newPassword.isEmpty && newPassword != currentPassword, "Distinta a la actual"),
        ]
    }

    private var canSubmit: Bool {
        !currentPassword.isEmpty &&
        rules.allSatisfy(\.ok) &&
        confirmPassword == newPassword &&
        !session.isWorking
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("logo_campusvote")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                VStack(spacing: 6) {
                    Text("Nueva contraseña")
                        .font(.headline)
                    Text("Debes cambiarla para entrar. Esta pantalla no se puede saltar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let message = session.errorMessage {
                    ErrorBanner(message: message)
                }

                field("Contraseña actual", text: $currentPassword, field: .current)
                field("Nueva contraseña", text: $newPassword, field: .new)
                field("Confirmar contraseña", text: $confirmPassword, field: .confirm)

                if !confirmPassword.isEmpty && confirmPassword != newPassword {
                    Text("La confirmación no coincide.")
                        .font(.caption)
                        .foregroundStyle(Color.campusGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(rules.enumerated()), id: \.offset) { _, rule in
                        HStack(spacing: 8) {
                            Image(systemName: rule.ok ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundStyle(rule.ok ? Color.campusGreen : Color.secondary)
                            Text(rule.text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    focus = nil
                    Task {
                        await session.changePassword(current: currentPassword, new: newPassword)
                    }
                } label: {
                    Group {
                        if session.isWorking {
                            ProgressView().tint(Color.onBrand)
                        } else {
                            Text("Guardar contraseña")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .foregroundStyle(Color.onBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.campusGreen))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .opacity(canSubmit || session.isWorking ? 1 : 0.6)

                Button("Cerrar sesión") {
                    Task { await session.logout() }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.campusTeal)
                .buttonStyle(.plain)
            }
            .padding(22)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func field(_ title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            SecureField(title, text: text)
                .font(.subheadline)
                .textContentType(field == .current ? .password : .newPassword)
                .focused($focus, equals: field)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
        }
    }
}
