import SwiftUI

struct NoticeLook {
    let label: String
    let symbol: String
    let tint: Color
}

enum NoticeStyle {
    static func look(type: String, event: String?) -> NoticeLook {
        let key = (event?.isEmpty == false) ? event! : type
        switch key {
        case "FAIR_OPENED", "FAIR_REVIEW_OPEN":
            return NoticeLook(label: "Feria abierta", symbol: "calendar.badge.checkmark", tint: .brand)
        case "FAIR_PREVIEW":
            return NoticeLook(label: "Vista previa", symbol: "eye", tint: .brand)
        case "JURY_ASSIGNED":
            return NoticeLook(label: "Jurado asignado", symbol: "person.badge.shield.checkmark", tint: .brand)
        case "RATING_RECEIVED":
            return NoticeLook(label: "Calificación recibida", symbol: "star", tint: .brandGold)
        case "RESULTS_PUBLISHED":
            return NoticeLook(label: "Resultados publicados", symbol: "trophy", tint: .brandGold)
        case "PROJECT_REVIEWED":
            return NoticeLook(label: "Revisión del proyecto", symbol: "checkmark.seal", tint: .brand)
        case "SYSTEM_ALERT":
            return NoticeLook(label: "Aviso institucional", symbol: "megaphone", tint: .brandGold)
        default:
            return NoticeLook(label: "Aviso", symbol: "bell", tint: .appNeutral)
        }
    }
}

enum NoticeGroups {
    static func sections(_ items: [JuryNotice]) -> [(label: String, items: [JuryNotice])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var order: [String] = []
        var grouped: [String: [JuryNotice]] = [:]
        for item in items {
            let label = dayLabel(item.createdAt, today: today, calendar: calendar)
            if grouped[label] == nil { order.append(label) }
            grouped[label, default: []].append(item)
        }
        return order.map { (label: $0, items: grouped[$0] ?? []) }
    }

    private static func dayLabel(_ date: Date?, today: Date, calendar: Calendar) -> String {
        guard let date else { return "ANTES" }
        let day = calendar.startOfDay(for: date)
        let delta = calendar.dateComponents([.day], from: day, to: today).day ?? 0
        if delta == 0 { return "HOY" }
        if delta == 1 { return "AYER" }
        return Self.dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_PE")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_PE")
        formatter.dateFormat = "dd/MM/yyyy · HH:mm"
        return formatter
    }()
}

struct NoticeDayHeader: View {
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
            Rectangle()
                .fill(Color.appNeutral.opacity(0.25))
                .frame(height: 1)
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brand)
        }
    }
}

struct NoticeCard: View {
    let notice: JuryNotice

    private var look: NoticeLook {
        NoticeStyle.look(type: notice.type, event: notice.event)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: look.symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(look.tint)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(look.tint.opacity(0.12)))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(look.label.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(0.6)
                            .foregroundStyle(look.tint)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if !notice.isRead {
                            Circle().fill(look.tint).frame(width: 7, height: 7)
                        }
                    }
                    ProseText(text: notice.title, font: .subheadline, weight: .semibold, lineLimit: 2)
                }
            }
            ProseText(text: notice.message, font: .caption, color: Color.appNeutral)
                .padding(.leading, 52)
            if let createdAt = notice.createdAt {
                Text(NoticeGroups.clockFormatter.string(from: createdAt))
                    .font(.caption2)
                    .foregroundStyle(Color.appNeutral.opacity(0.8))
                    .padding(.leading, 52)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(notice.isRead ? Color.appNeutral.opacity(0.14) : look.tint.opacity(0.35), lineWidth: 1)
        }
        .opacity(notice.isRead ? 0.72 : 1)
    }
}
