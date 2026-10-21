import SwiftUI

struct FilaDeFeria: View {
    @Environment(\.locale) private var locale
    let fair: Fair
    let status: FairStatus

    enum FairStatus {
        case open, scheduled, closed
    }

    private var statusConfig: (text: String, textColor: Color, bgColor: Color, borderColor: Color) {
        switch status {
        case .open:
            return ("Abierta", Color.onBrand, Color.brand, Color.clear)
        case .scheduled:
            return ("Programada", Color.brandGold, Color.brandGold.opacity(0.12), Color.brandGold.opacity(0.3))
        case .closed:
            return ("Cerrada", Color.appNeutral, Color.appNeutral.opacity(0.12), Color.appNeutral.opacity(0.3))
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(fair.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(status == .closed ? Color.appNeutral : Color.brand)
                    .lineLimit(2)

                if let site = fair.siteName, !site.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appNeutral)
                        Text(site)
                            .font(.caption)
                            .foregroundStyle(Color.appNeutral)
                    }
                }
            }

            Spacer(minLength: 8)

            Text(L10n.tr(statusConfig.text, locale: locale))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(statusConfig.textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusConfig.bgColor)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(statusConfig.borderColor, lineWidth: 1))

            if status == .open {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appNeutral.opacity(0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(status == .open ? Color.brand.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .shadow(color: status == .open ? Color.brand.opacity(0.08) : .clear, radius: 8, y: 4)
        .opacity(status == .closed ? 0.8 : 1.0)
    }
}
