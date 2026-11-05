import Foundation

enum ReviewScope: String, CaseIterable, Identifiable {
    case assigned, all
    var id: String { rawValue }
    var title: String { self == .assigned ? "Mis categorías" : "Toda la feria" }
}

enum FairPhase: String, Decodable {
    case beforePreview = "BEFORE_PREVIEW"
    case preview = "PREVIEW"
    case live = "LIVE"
    case ended = "ENDED"

    static func parse(_ raw: String?) -> FairPhase? {
        switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "LIVE", "OPEN", "ABIERTA", "ACTIVE", "IN_PROGRESS", "ONGOING":
            return .live
        case "PREVIEW", "VISTA_PREVIA":
            return .preview
        case "BEFORE_PREVIEW", "SCHEDULED", "PROGRAMADA", "DRAFT", "UPCOMING":
            return .beforePreview
        case "ENDED", "CLOSED", "CERRADA", "FINISHED":
            return .ended
        default:
            return nil
        }
    }
}

struct ReviewAccess: Decodable, Hashable {
    let phase: FairPhase?
    let reviewOpensAt: String?
    let canReview: Bool?

    enum CodingKeys: String, CodingKey {
        case phase
        case reviewOpensAt = "review_opens_at"
        case canReview = "can_review"
        case access
        case reviewAccess = "review_access"
    }

    init(phase: FairPhase? = nil, reviewOpensAt: String? = nil, canReview: Bool? = nil) {
        self.phase = phase
        self.reviewOpensAt = reviewOpensAt
        self.canReview = canReview
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawPhase = try? values.decodeIfPresent(String.self, forKey: .phase)
        var parsed = FairPhase.parse(rawPhase)
        var opensAt = try? values.decodeIfPresent(String.self, forKey: .reviewOpensAt)
        var allowed = Self.flexibleBool(values, key: .canReview)

        for key in [CodingKeys.access, .reviewAccess] {
            guard let nested = try? values.decode(ReviewAccess.self, forKey: key) else { continue }
            parsed = parsed ?? nested.phase
            opensAt = opensAt ?? nested.reviewOpensAt
            allowed = allowed ?? nested.canReview
        }

        phase = parsed
        reviewOpensAt = opensAt
        canReview = allowed
    }

    func merging(_ fallback: ReviewAccess) -> ReviewAccess {
        ReviewAccess(
            phase: phase ?? fallback.phase,
            reviewOpensAt: reviewOpensAt ?? fallback.reviewOpensAt,
            canReview: canReview ?? fallback.canReview
        )
    }

    func resolved(status: String?, startsAt: String? = nil) -> ReviewAccess {
        let fromStatus = FairPhase.parse(status)
        let chosen: FairPhase
        if fromStatus == .live {
            chosen = .live
        } else if let phase {
            chosen = phase
        } else {
            chosen = fromStatus ?? .beforePreview
        }
        return ReviewAccess(
            phase: chosen,
            reviewOpensAt: reviewOpensAt ?? startsAt,
            canReview: canReview
        )
    }

    var allowsReview: Bool { phase == .live && canReview != false }
    var allowsBrowsing: Bool { phase == .preview || phase == .live || phase == .ended }

    func notice(locale: Locale) -> String? {
        switch phase {
        case .ended: return L10n.tr("La feria terminó", locale: locale)
        case .preview:
            if let date = openingDate {
                let formatted = date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened,
                                                               locale: locale, timeZone: .current))
                return L10n.format("Disponible para calificar desde %@", locale: locale, formatted)
            }
            return L10n.tr("Podrás calificar cuando empiece la feria", locale: locale)
        case .beforePreview:
            return L10n.tr("Verás los proyectos cuando cierre la inscripción", locale: locale)
        case .live where canReview == false:
            return L10n.tr("Podrás calificar cuando empiece la feria", locale: locale)
        case .none:
            return L10n.tr("Podrás calificar cuando empiece la feria", locale: locale)
        case .live: return nil
        }
    }

    private var openingDate: Date? {
        guard let reviewOpensAt else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: reviewOpensAt) { return date }
        parser.formatOptions = [.withInternetDateTime]
        return parser.date(from: reviewOpensAt)
    }

    private static func flexibleBool(
        _ values: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Bool? {
        if let value = try? values.decodeIfPresent(Bool.self, forKey: key) { return value }
        if let value = try? values.decodeIfPresent(Int.self, forKey: key) { return value != 0 }
        if let text = try? values.decodeIfPresent(String.self, forKey: key) {
            switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "yes", "si", "sí": return true
            case "false", "0", "no": return false
            default: return nil
            }
        }
        return nil
    }
}
