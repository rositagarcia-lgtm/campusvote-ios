import SwiftUI


struct CodeInputView: View {
    @Binding var code: String
    var length: Int = 6
    var onComplete: () -> Void = {}

    @FocusState private var focused: Bool

    // MARK: - Paleta de Colores Premium (Dinámica)
    private let brandColor = Color.brand
    private let neutralColor = Color.appNeutral
    private let cardColor = Color.cardBackground

    var body: some View {
        ZStack {
            // MARK: - Visualización de Cajas
            HStack(spacing: 12) {
                ForEach(0..<length, id: \.self) { index in
                    box(at: index)
                }
            }

            // MARK: - Campo de Texto Oculto (Captura de entrada y pegado)
            TextField("", text: Binding(
                get: { code },
                set: { nuevo in
                    // Filtra solo números y limita a la longitud máxima
                    let limpio = String(nuevo.filter(\.isNumber).prefix(length))
                    guard limpio != code else { return }
                    
                    // Anima la transición de los dígitos
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        code = limpio
                    }
                    
                    // Dispara la acción al completar, con un micro-delay para renderizar la última caja
                    if limpio.count == length {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onComplete()
                        }
                    }
                }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode) // Habilita autocompletado de SMS en iOS
            .textFieldStyle(.plain)
            .focused($focused)
            .foregroundStyle(.clear)
            .tint(.clear)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
        .contentShape(Rectangle()) // Hace que toda el área sea clicable para enfocar
        .onTapGesture { focused = true }
        .task { focused = true } // Enfoca automáticamente al aparecer
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Código de verificación de 6 dígitos")
        .accessibilityValue(code.isEmpty ? "vacío" : code.map(String.init).joined(separator: ", "))
    }

    // MARK: - Renderizado de Cada Casilla
    @ViewBuilder
    private func box(at index: Int) -> some View {
        let digits = Array(code)
        let isFilled = index < digits.count
        let isCurrent = focused && index == digits.count
        
        let character = isFilled ? String(digits[index]) : ""

        ZStack {
            // 1. Fondo y Borde Dinámico
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrent ? brandColor.opacity(0.08) : (isFilled ? cardColor : neutralColor.opacity(0.05)))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isCurrent ? brandColor : (isFilled ? brandColor.opacity(0.3) : neutralColor.opacity(0.2)),
                            lineWidth: isCurrent ? 1.5 : 1.0
                        )
                )
                .shadow(
                    color: isCurrent ? brandColor.opacity(0.15) : .clear,
                    radius: 8,
                    y: 4
                )

            // 2. Contenido: Dígito, Cursor o Punto Pendiente
            if isFilled {
                Text(character)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(brandColor)
            } else if isCurrent {
                // Cursor parpadeante premium
                Rectangle()
                    .fill(brandColor)
                    .frame(width: 2, height: 32)
                    .opacity(focused ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: focused)
            } else {
                // Indicador de posición vacía sutil
                Circle()
                    .fill(neutralColor.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(height: 64)
        // Micro-interacción: la caja crece ligeramente al llenarse
        .scaleEffect(isFilled ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFilled)
        .allowsHitTesting(false) // Los toques los maneja el ZStack padre
    }
}

// MARK: - Preview de Validación
#Preview {
    struct PreviewWrapper: View {
        @State private var code = ""
        
        var body: some View {
            VStack(spacing: 32) {
                Text("Ingresa el código enviado a tu correo")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appNeutral)
                
                CodeInputView(code: $code, length: 6) {
                    print("Código completado: \(code)")
                }
                
                Button("Simular Error") {
                    code = "" // Reset para probar animación de salida
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brand)
            }
            .padding()
            .background(Color.appBackground.ignoresSafeArea())
        }
    }
    return PreviewWrapper()
}
