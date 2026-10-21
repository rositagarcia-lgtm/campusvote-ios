import SwiftUI

struct FairsSectionView<Content: View>: View {
    @Environment(\.locale) private var locale
    let title: String
    let count: Int
    var isHighlighted = false
    let isEmpty: Bool
    var isLoading = false
    let emptyTitle: String
    let emptyMessage: String
    let emptyIcon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.tr(title, locale: locale))
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(isHighlighted ? Color.brand : Color.appNeutral)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appNeutral)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appNeutral.opacity(0.1))
                    .clipShape(Capsule())
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if isEmpty {
                FairsEmptyStateView(title: emptyTitle, message: emptyMessage, icon: emptyIcon)
            } else {
                VStack(spacing: 12) {
                    content()
                }
            }
        }
    }
}

struct FairsEmptyStateView: View {
    @Environment(\.locale) private var locale
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Color.appNeutral.opacity(0.4))
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.appNeutral.opacity(0.08)))

            Text(L10n.tr(title, locale: locale))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brand)

            Text(L10n.tr(message, locale: locale))
                .font(.caption)
                .foregroundStyle(Color.appNeutral)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appNeutral.opacity(0.1), lineWidth: 1))
    }
}
