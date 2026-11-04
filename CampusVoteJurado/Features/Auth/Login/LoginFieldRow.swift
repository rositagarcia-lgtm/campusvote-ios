import SwiftUI

struct PremiumFieldRow<Content: View>: View {
    @Environment(\.locale) private var locale
    let icon: String
    let label: String
    let isFocused: Bool
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.campusGreen)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.iconTile)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr(label, locale: locale))
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(isFocused ? Color.campusGreen : Color.appNeutral)

                content
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isFocused ? Color.campusGreen : Color.cardBorder, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
