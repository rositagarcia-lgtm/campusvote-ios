import SwiftUI

/// Paleta institucional de CampusVote (verde #00695C y dorado #D4AF37),
/// reutilizada por todas las pantallas del jurado.
enum JuryTheme {
    /// Verde oscuro institucional (#00695C).
    static let brand = Color(red: 0.0, green: 0.412, blue: 0.361)
    /// Verde brand algo más oscuro para textos sobre fondo claro.
    static let brandDeep = Color(red: 0.0, green: 0.30, blue: 0.26)
    /// Verde menta suave para chips y acentos (#D7F5EC).
    static let mint = Color(red: 0.843, green: 0.961, blue: 0.925)
    /// Texto verde sobre el chip menta (#00705C).
    static let mintText = Color(red: 0.0, green: 0.439, blue: 0.361)
    /// Dorado institucional para badges de estado (#D4AF37).
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
    /// Dorado especiado (borde) para el badge ACTIVA.
    static let goldDeep = Color(red: 0.72, green: 0.56, blue: 0.12)
    /// Gris claro para fondos y chips neutros.
    static let surface = Color(.systemGray6)
    /// Color de acento global del asset catalog para los controles nativos.
    static var accent: Color { .accentColor }
}

extension Color {
    /// Verde oscuro institucional CampusVote.
    static var juryBrand: Color { JuryTheme.brand }
    /// Verde menta para badges y acentos.
    static var juryMint: Color { JuryTheme.mint }
}

/// Tipografía auxiliar para el dashboard (grande y media, con tracking).
enum JuryTypography {
    static func display(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .tracking(-0.5)
    }

    static func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(2)
    }
}