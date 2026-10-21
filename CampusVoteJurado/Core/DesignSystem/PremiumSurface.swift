import SwiftUI

enum AppSpacing {
    static let compact: CGFloat = 8
    static let standard: CGFloat = 12
    static let section: CGFloat = 16
    static let screen: CGFloat = 20
    static let large: CGFloat = 24
}

private struct PremiumSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let raised: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(raised ? 0.07 : 0.025),
                radius: raised ? 12 : 4,
                y: raised ? 5 : 2
            )
    }
}

extension View {
    func premiumSurface(cornerRadius: CGFloat = 16, raised: Bool = false) -> some View {
        modifier(PremiumSurfaceModifier(cornerRadius: cornerRadius, raised: raised))
    }
}

struct StatusBadge: View {
    enum Style {
        case pending
        case reviewed
        case neutral

        var color: Color {
            switch self {
            case .pending: return .appWarning
            case .reviewed: return .appSuccess
            case .neutral: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .reviewed: return "checkmark.circle.fill"
            case .neutral: return "circle.fill"
            }
        }
    }

    @Environment(\.locale) private var locale
    let title: String
    let style: Style

    var body: some View {
        Label(L10n.tr(title, locale: locale), systemImage: style.icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(style.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(style.color.opacity(0.12)))
            .accessibilityElement(children: .combine)
    }
}

struct ScreenStateView: View {
    @Environment(\.locale) private var locale
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.standard) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.brand)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.brand.opacity(0.1)))

            Text(L10n.tr(title, locale: locale))
                .font(.headline)
                .foregroundStyle(.primary)

            Text(L10n.tr(message, locale: locale))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(L10n.tr(actionTitle, locale: locale), action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(Color.brand))
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity)
        .premiumSurface()
    }
}
