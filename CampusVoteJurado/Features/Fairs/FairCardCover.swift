import SwiftUI

struct FairCardCover: View {
    @Environment(\.locale) private var locale
    let url: URL?
    let status: FairCardStatus

    private var onImage: Bool { url != nil }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url {
                CoverImage(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                LinearGradient(
                    colors: [Color.black.opacity(0.08), Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [Color.brand.opacity(0.16), Color.brand.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            statusRow
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: url == nil ? 88 : 142)
        .accessibilityElement(children: .combine)
    }

    private var statusRow: some View {
        HStack(spacing: 10) {
            Image(systemName: status == .open || status == .preview
                  ? "calendar.badge.checkmark"
                  : "calendar.badge.minus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(status == .open || status == .preview ? Color.brand : Color.appNeutral)
                .frame(width: 40, height: 40)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Spacer(minLength: 8)
            if status != .open {
                badge
            }
        }
    }

    private var badge: some View {
        HStack(spacing: 6) {
            Image(systemName: badgeIcon)
                .font(.system(size: 12, weight: .semibold))
            Text(L10n.tr(badgeTitle, locale: locale).uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.6)
        }
        .foregroundStyle(onImage ? Color.white : tone)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if onImage {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
            } else {
                Capsule().fill(tone.opacity(0.12))
            }
        }
    }

    private var badgeTitle: String {
        switch status {
        case .open: return ""
        case .preview: return "Vista previa"
        case .scheduled: return "Programada"
        case .closed: return "Terminó"
        }
    }

    private var badgeIcon: String {
        switch status {
        case .open: return "flag.checkered"
        case .preview: return "eye"
        case .scheduled: return "hourglass"
        case .closed: return "flag.checkered"
        }
    }

    private var tone: Color {
        switch status {
        case .open: return Color.brand
        case .preview: return Color(red: 0.85, green: 0.47, blue: 0.02)
        case .scheduled: return Color(red: 0.01, green: 0.52, blue: 0.78)
        case .closed: return Color.appNeutral
        }
    }
}
