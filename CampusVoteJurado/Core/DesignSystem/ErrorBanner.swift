import SwiftUI

struct ErrorBanner: View {
    @Environment(\.locale) private var locale
    let message: String

    private let errorColor = Color.appDanger

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(errorColor)
                .frame(width: 24, height: 24)
                .padding(.top, 1)

            Text(L10n.tr(message, locale: locale))
                .font(.footnote.weight(.medium))
                .foregroundStyle(errorColor)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(errorColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(errorColor.opacity(0.25), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.format("Error: %@", locale: locale, message))
    }
}

// MARK: - Preview de Validación
#Preview {
    VStack(spacing: 20) {
        // Estado sin error (para visualizar el espacio)
        Text("Formulario normal")
            .foregroundStyle(.secondary)
        
        // Estado con error
        ErrorBanner(message: "Credenciales incorrectas. Verifica tu correo institucional o contacta a soporte.")
        
        // Estado con error largo (prueba de multilínea)
        ErrorBanner(message: "Tu sesión ha expirado por inactividad. Por favor, vuelve a iniciar sesión para continuar evaluando los proyectos.")
    }
    .padding()
    .background(Color.appBackground.ignoresSafeArea())
}
