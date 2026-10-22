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
}

/// Campos opcionales: compatible con el backend anterior y fases futuras desconocidas.
struct ReviewAccess: Decodable, Hashable {
    let phase: FairPhase?
    let reviewOpensAt: String?
    let canReview: Bool?

    enum CodingKeys: String, CodingKey {
        case phase
        case reviewOpensAt = "review_opens_at"
        case canReview = "can_review"
    }

    init(phase: FairPhase? = nil, reviewOpensAt: String? = nil, canReview: Bool? = nil) {
        self.phase = phase
        self.reviewOpensAt = reviewOpensAt
        self.canReview = canReview
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try values.decodeIfPresent(String.self, forKey: .phase)
        phase = raw.map { FairPhase(rawValue: $0) ?? .beforePreview }
        reviewOpensAt = try values.decodeIfPresent(String.self, forKey: .reviewOpensAt)
        canReview = try values.decodeIfPresent(Bool.self, forKey: .canReview)
    }

    func merging(_ fallback: ReviewAccess) -> ReviewAccess {
        ReviewAccess(phase: phase ?? fallback.phase, reviewOpensAt: reviewOpensAt ?? fallback.reviewOpensAt,
                     canReview: canReview ?? fallback.canReview)
    }

    func resolved(status: String?, startsAt: String? = nil) -> ReviewAccess {
        let fallback: FairPhase = status?.uppercased() == "OPEN" ? .live
            : (status?.uppercased() == "CLOSED" ? .ended : .beforePreview)
        return ReviewAccess(phase: phase ?? fallback, reviewOpensAt: reviewOpensAt ?? startsAt,
                            canReview: canReview)
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
}
