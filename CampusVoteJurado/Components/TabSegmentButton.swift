import SwiftUI

struct TabSegmentButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let activeColor: Color
    let activeBadgeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .bold(isSelected)
                    .foregroundColor(isSelected ? .primary : .secondary)

                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? activeColor : .secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(isSelected ? activeBadgeColor : Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color(.systemBackground) : Color.clear)
            .cornerRadius(10)
        }
    }
}
