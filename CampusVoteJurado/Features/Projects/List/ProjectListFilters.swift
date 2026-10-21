import SwiftUI

struct ProjectRoute: Hashable {
    let id: String
}

enum StatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case rated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .pending: return "Sin reseña"
        case .rated: return "Evaluados"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .pending: return "clock"
        case .rated: return "checkmark"
        }
    }

    func tint(brand: Color, naranja: Color, verde: Color) -> Color {
        switch self {
        case .all: return brand
        case .pending: return naranja
        case .rated: return verde
        }
    }
}
