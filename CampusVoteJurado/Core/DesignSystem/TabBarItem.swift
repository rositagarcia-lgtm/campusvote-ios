import SwiftUI

struct TabBarItem: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let icon: String
    let label: String
    let isSelected: Bool
    let activeColor: Color

    init(
        icon: String,
        label: String,
        isSelected: Bool,
        activeColor: Color = .brand
    ) {
        self.icon = icon
        self.label = label
        self.isSelected = isSelected
        self.activeColor = activeColor
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .medium))
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .foregroundStyle(isSelected ? activeColor : Color.appNeutral)

            Text(label)
                .font(.caption2.weight(isSelected ? .semibold : .medium))
                .tracking(0.2)
                .foregroundStyle(isSelected ? Color.primary : Color.appNeutral)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(
            reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1),
            value: isSelected
        )
    }
}
