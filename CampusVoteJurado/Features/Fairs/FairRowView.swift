import SwiftUI

struct FilaDeFeria: View {
    @Environment(\.locale) private var locale
    let fair: Fair
    let status: FairStatus
    let onOpen: () -> Void

    enum FairStatus {
        case open, preview, scheduled, closed
    }

    private var coverURL: URL? {
        fair.coverUrl.flatMap { URL(string: $0) }
    }

    private var place: String? {
        if let site = fair.siteName, !site.isEmpty { return site }
        if let organization = fair.organizationName, !organization.isEmpty { return organization }
        return nil
    }

    private var pill: (text: String, foreground: Color, background: Color) {
        switch status {
        case .open:
            return ("En curso", Color.onBrand, Color.brand)
        case .preview:
            return ("Vista previa", Color.brand, Color.brand.opacity(0.12))
        case .scheduled:
            return ("Programada", Color.appWarning, Color.appWarning.opacity(0.16))
        case .closed:
            return ("Cerrada", Color.secondary, Color.primary.opacity(0.08))
        }
    }

    private var notice: (icon: String, text: String) {
        switch status {
        case .open:
            return ("info.circle.fill", "La feria está en curso: evalúa y deja tus reseñas.")
        case .preview:
            return ("calendar", "Podrás calificar cuando empiece la feria.")
        case .scheduled:
            return ("calendar", "Esta feria todavía no abre.")
        case .closed:
            return ("lock.fill", "La feria terminó.")
        }
    }

    private var buttonTitle: String {
        status == .open ? "Abrir feria" : "Ver feria"
    }

    private var showsButton: Bool {
        status != .scheduled
    }

    var body: some View {
        Group {
            if showsButton {
                Button(action: onOpen) {
                    card
                }
                .buttonStyle(.plain)
            } else {
                card
            }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 176)
                .overlay {
                    CoverImage(url: coverURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .allowsHitTesting(false)
                }
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(L10n.tr(pill.text, locale: locale))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(pill.foreground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(pill.background))
                        .padding(10)
                        .allowsHitTesting(false)
                }

            VStack(alignment: .leading, spacing: 10) {
                Text(fair.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let place {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .font(.system(size: 13, weight: .semibold))
                        Text(place)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                if let description = fair.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Label(L10n.tr(notice.text, locale: locale), systemImage: notice.icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.brand)
                    .fixedSize(horizontal: false, vertical: true)

                if showsButton {
                    HStack(spacing: 6) {
                        Text(L10n.tr(buttonTitle, locale: locale))
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.brand)
                    )
                    .allowsHitTesting(false)
                }
            }
            .padding(16)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .premiumSurface()
    }
}
