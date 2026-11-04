import SwiftUI

struct FilaDeFeria: View {
    @Environment(\.locale) private var locale
    let fair: Fair
    let status: FairStatus

    enum FairStatus {
        case open, preview, scheduled, closed
    }

    private var statusConfig: (text: String, textColor: Color, bgColor: Color) {
        switch status {
        case .open:
            return ("Abierta", Color.onBrand, Color.brand)
        case .preview:
            return ("Vista previa", Color.brand, Color.brand.opacity(0.12))
        case .scheduled:
            return ("Programada", Color.appWarning, Color.appWarning.opacity(0.12))
        case .closed:
            return ("Cerrada", Color.appNeutral, Color.appNeutral.opacity(0.12))
        }
    }

    private var showsChevron: Bool {
        status == .open || status == .preview || status == .closed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImage(url: fair.coverURL)
                .frame(maxWidth: .infinity)
                .frame(height: 148)
                .clipped()

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(fair.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(status == .closed ? Color.secondary : Color.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        Text(L10n.tr(statusConfig.text, locale: locale))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(statusConfig.textColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(statusConfig.bgColor))
                    }

                    if let description = fair.description?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(Color.appNeutral)
                            .lineLimit(2)
                    }

                    if let site = fair.siteName, !site.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                            Text(site)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color.appNeutral)
                    }
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.iconTile))
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSurface(raised: status == .open)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
