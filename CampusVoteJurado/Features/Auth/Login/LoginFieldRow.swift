import SwiftUI

// MARK: - Componente de Campo Premium
struct PremiumFieldRow<Content: View>: View {
    @Environment(\.locale) private var locale
    let icon: String
    let label: String
    let isFocused: Bool
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isFocused ? Color(light: 0xFFFFFF, dark: 0x0E1514) : Color.campusGreen.opacity(0.6))
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(isFocused ? Color.campusGreen : Color.iconTile)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.tr(label, locale: locale))
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(isFocused ? Color.campusGreen : Color.appNeutral)

                content.foregroundStyle(Color.campusGreen)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? Color.campusGreen : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
