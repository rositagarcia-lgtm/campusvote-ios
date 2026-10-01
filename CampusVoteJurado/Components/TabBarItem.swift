import SwiftUI

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let activeColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
            Text(label)
                .font(.caption2.weight(isSelected ? .semibold : .regular))
        }
        .foregroundStyle(isSelected ? activeColor : Color.primary)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
