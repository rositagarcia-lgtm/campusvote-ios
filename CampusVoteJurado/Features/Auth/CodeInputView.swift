import SwiftUI
struct CodeInputView: View {
    @Binding var code: String
    var length = 6
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, nuevo in
                    // Solo dígitos y como máximo `length`.
                    let limpio = String(nuevo.filter(\.isNumber).prefix(length))
                    if limpio != nuevo {
                        code = limpio
                    }
                }

            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    box(at: index)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .onAppear { focused = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Código de verificación")
        .accessibilityValue(code.isEmpty ? "vacío" : code.map(String.init).joined(separator: " "))
    }

    /// Casilla llena (dígito), actual (cursor y fondo menta) o pendiente (punto).
    @ViewBuilder
    private func box(at index: Int) -> some View {
        let digits = Array(code)
        let isCurrent = focused && index == digits.count

        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrent ? Color.brandMint : Color.iconTile)
                .shadow(color: isCurrent ? .black.opacity(0.08) : .clear, radius: 8, y: 3)

            if index < digits.count {
                Text(String(digits[index]))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.brand)
            } else if isCurrent {
                Rectangle()
                    .fill(Color.brand)
                    .frame(width: 2, height: 30)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .frame(height: 64)
    }
}
