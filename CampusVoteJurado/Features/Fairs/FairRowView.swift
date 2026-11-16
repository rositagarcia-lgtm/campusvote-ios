import SwiftUI

enum FairCardStatus {
    case open, preview, scheduled, closed
}

struct FilaDeFeria: View {
    @Environment(\.locale) private var locale
    let fair: Fair
    let status: FairCardStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FairCardCover(url: fair.coverURL, status: status)
            VStack(alignment: .leading, spacing: 10) {
                ProseText(
                    text: fair.name,
                    font: .title3,
                    weight: .bold,
                    lineLimit: 2
                )
                if let site = fair.siteName?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !site.isEmpty {
                    Label(site, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundStyle(Color.appNeutral)
                        .lineLimit(1)
                }
                if let description = fair.description?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !description.isEmpty {
                    ProseText(
                        text: description,
                        font: .subheadline,
                        lineLimit: 2
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                footer
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.appNeutral.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 10) {
                statusLabel
                actionPill
            }
            VStack(alignment: .leading, spacing: 10) {
                statusLabel
                actionPill.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var statusLabel: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: lineIcon)
                .font(.system(size: 16, weight: .semibold))
            Text(statusLine)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tone)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var actionPill: some View {
        if let actionTitle {
            HStack(spacing: 6) {
                Text(L10n.tr(actionTitle, locale: locale))
                Image(systemName: actionIcon)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.onBrand)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.brand))
            .fixedSize()
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

    private var lineIcon: String {
        switch status {
        case .open: return "clock"
        case .preview, .scheduled: return "hourglass"
        case .closed: return "flag.checkered"
        }
    }

    private var actionTitle: String? {
        switch status {
        case .open: return "Abrir feria"
        case .closed: return "Ver mi participación"
        case .preview, .scheduled: return nil
        }
    }

    private var actionIcon: String {
        switch status {
        case .open: return "arrow.right"
        case .preview: return "eye"
        case .closed: return "checklist"
        case .scheduled: return "arrow.right"
        }
    }

    private var statusLine: String {
        switch status {
        case .open:
            if let end = Self.date(from: fair.endsAt), let span = Self.span(until: end, locale: locale) {
                return L10n.format("Cierra en %@", locale: locale, span)
            }
            return L10n.tr("La feria está en curso: evalúa y deja tus reseñas.", locale: locale)
        case .preview:
            let raw = fair.access.reviewOpensAt ?? fair.startsAt
            if let start = Self.date(from: raw), let span = Self.span(until: start, locale: locale) {
                return L10n.format("Podrás calificar en %@", locale: locale, span)
            }
            return L10n.tr("Ya puedes estudiar los proyectos de tu categoría.", locale: locale)
        case .scheduled:
            return L10n.tr("Verás los proyectos de tu categoría cuando cierre la inscripción.", locale: locale)
        case .closed:
            return L10n.tr("La feria terminó. Tus evaluaciones quedan registradas.", locale: locale)
        }
    }

    private static func date(from raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: raw) { return date }
        parser.formatOptions = [.withInternetDateTime]
        return parser.date(from: raw)
    }

    private static func span(until date: Date, locale: Locale) -> String? {
        let seconds = Int(date.timeIntervalSinceNow)
        guard seconds > 0 else { return nil }
        let days = seconds / 86_400
        if days >= 2 { return L10n.format("%d días", locale: locale, days) }
        if days == 1 { return L10n.tr("1 día", locale: locale) }
        let hours = seconds / 3_600
        if hours >= 2 { return L10n.format("%d horas", locale: locale, hours) }
        if hours == 1 { return L10n.tr("1 hora", locale: locale) }
        return L10n.tr("menos de una hora", locale: locale)
    }
}
