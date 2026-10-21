import SwiftUI

struct ErrorBanner: View {
    @Environment(\.locale) private var locale
    let message: String

    // MARK: - Paleta de Error Premium
    // Un rojo refinado que mantiene la urgencia sin ser visualmente agresivo
    private let errorColor = Color(red: 0.92, green: 0.26, blue: 0.26)

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // MARK: - Ícono de Advertencia
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(errorColor)
                .frame(width: 24, height: 24) // Alineación precisa con el texto
                .padding(.top, 1)

            // MARK: - Mensaje de Error
            Text(L10n.tr(message, locale: locale))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(errorColor)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true) // Permite multilínea sin cortar
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        // Fondo suave para no saturar la interfaz
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(errorColor.opacity(0.08))
        )
        // Borde sutil para definir el límite del banner
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(errorColor.opacity(0.25), lineWidth: 1)
        )
        // Transición suave al aparecer/desaparecer
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
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
