import SwiftUI

struct CodeInputView: View {
    @Binding var code: String
    var length = 6
    var onComplete: () -> Void = {}

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    box(at: index)
                }
            }

            TextField("", text: Binding(
                get: { code },
                set: { nuevo in
                    let limpio = String(nuevo.filter(\.isNumber).prefix(length))
                    guard limpio != code else { return }
                    code = limpio
                    if limpio.count == length {
                        onComplete()
                    }
                }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .textFieldStyle(.plain)
            .focused($focused)
            .foregroundStyle(.clear)
            .tint(.clear)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .task { focused = true }
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
                    .foregroundStyle(Color.campusGreen)
            } else if isCurrent {
                Rectangle()
                    .fill(Color.campusGreen)
                    .frame(width: 2, height: 30)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .frame(height: 64)
        .allowsHitTesting(false)
    }
}
