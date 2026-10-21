import SwiftUI

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var hasLength: Bool { newPassword.count >= 8 }
    private var hasUpper: Bool { newPassword.contains(where: \.isUppercase) }
    private var hasLower: Bool { newPassword.contains(where: \.isLowercase) }
    private var hasNumber: Bool { newPassword.contains(where: \.isNumber) }
    private var hasSymbol: Bool { newPassword.contains(where: { !$0.isLetter && !$0.isNumber }) }
    private var canSave: Bool {
        !current.isEmpty && hasLength && hasUpper && hasLower && hasNumber && hasSymbol && newPassword == confirm && !isSaving
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetTopBar(title: "Contraseña") { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield")
                            .font(.title3)
                            .foregroundStyle(Color.brand)
                            .frame(width: 40, height: 40)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.12)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seguridad de la cuenta").font(.subheadline.weight(.semibold))
                            Text("Jurado Evaluador Institucional")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))

                    secretField("Contraseña actual", text: $current, visible: $showCurrent, prompt: "Ingresa tu contraseña actual")
                    secretField("Nueva contraseña", text: $newPassword, visible: $showNew, prompt: "Ingresa tu nueva contraseña")
                    secretField("Confirmar nueva contraseña", text: $confirm, visible: $showConfirm, prompt: "Repite la nueva contraseña")

                    VStack(alignment: .leading, spacing: 8) {
                        Label("REQUISITOS DE SEGURIDAD", systemImage: "clock")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("La contraseña debe contener un mínimo de 8 caracteres, al menos una mayúscula, una minúscula, un número y un símbolo especial.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        requirement("8+ caracteres", met: hasLength)
                        requirement("Mayúscula y minúscula", met: hasUpper && hasLower)
                        requirement("Al menos 1 número", met: hasNumber)
                        requirement("Símbolo especial", met: hasSymbol)
                        if !confirm.isEmpty && confirm != newPassword {
                            Text("La confirmación no coincide.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    Button(action: save) {
                        Group {
                            if isSaving {
                                ProgressView().tint(Color.onBrand)
                            } else {
                                Text("Guardar contraseña")
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.onBrand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand))
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.6)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground)
    }

    private func secretField(_ title: String, text: Binding<String>, visible: Binding<Bool>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr(title, locale: locale)).font(.subheadline)
            HStack {
                Group {
                    if visible.wrappedValue {
                        TextField(L10n.tr(prompt, locale: locale), text: text)
                    } else {
                        SecureField(L10n.tr(prompt, locale: locale), text: text)
                    }
                }
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                Button {
                    visible.wrappedValue.toggle()
                } label: {
                    Image(systemName: visible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
        }
    }

    private func requirement(_ title: String, met: Bool) -> some View {
        Label(L10n.tr(title, locale: locale), systemImage: met ? "checkmark.circle.fill" : "circle")
            .font(.caption)
            .foregroundStyle(met ? Color.brand : .secondary)
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        let body = PasswordUpdate(currentPassword: current, newPassword: newPassword)
        Task {
            do {
                try await APIClient.shared.send(
                    Endpoint(path: "users/me/password", method: "POST", body: body)
                )
                dismiss()
            } catch {
                errorMessage = error.userMessage
                isSaving = false
            }
        }
    }
}
