import SwiftUI

struct ProfileSettingsCard: View {
    @Environment(\.locale) private var locale
    let onPassword: () -> Void
    let onPreferences: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ajustes:")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button(action: onPassword) {
                    settingsRow(icon: "lock.shield", title: "Seguridad y Credenciales", subtitle: "Contraseña, 2FA y acceso")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 74)

                Button(action: onPreferences) {
                    settingsRow(icon: "gearshape", title: "Preferencias", subtitle: "Tema, idioma y tamaño de texto")
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        }
        .padding(.top, 4)
    }

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.brand)
                .frame(width: 42, height: 42)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.1)))
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.tr(title, locale: locale))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(L10n.tr(subtitle, locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct ProfileLogoutButton: View {
    let isLoggingOut: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoggingOut {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
                Text("Cerrar sesión")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.red)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoggingOut)
    }
}
