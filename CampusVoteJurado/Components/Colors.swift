import SwiftUI
import UIKit

/// Colores de CampusVote.
/// Compatible con modo claro y oscuro.
extension Color {

    // MARK: - Colores principales

    /// Verde principal de CampusVote.
    /// Botones, títulos e íconos principales.
    static let brand = Color(light: 0x004D40, dark: 0x4DB6AC)

    /// Verde secundario.
    /// Enlaces, acciones secundarias e íconos.
    static let brandTeal = Color(light: 0x00695C, dark: 0x80CBC4)

    /// Dorado de CampusVote.
    /// Acentos, indicadores y detalles importantes.
    static let brandGold = Color(light: 0xD4AF37, dark: 0xE0C060)

    /// Color neutro.
    static let appNeutral = Color(light: 0x8E8E93, dark: 0x98989F)


    // MARK: - Colores sobre fondos

    /// Texto que aparece encima del verde principal.
    static let onBrand = Color(light: 0xFFFFFF, dark: 0x0E1514)


    // MARK: - Colores suaves

    /// Verde principal con transparencia.
    static let appPrimaryLight = Color(light: 0x004D40, dark: 0x4DB6AC)
        .opacity(0.12)

    /// Dorado suave.
    static let appTertiaryLight = Color(light: 0xD4AF37, dark: 0xE0C060)
        .opacity(0.20)

    /// Menta suave para fondos, halos y estados activos.
    static let brandMint = Color(light: 0xD9F3EE, dark: 0x1B3A35)


    // MARK: - Fondos

    /// Fondo general de las pantallas.
    static let appBackground = Color(light: 0xF7F8FC, dark: 0x0E1514)

    /// Fondo de tarjetas.
    static let cardBackground = Color(light: 0xFFFFFF, dark: 0x16211F)

    /// Fondo de cajas de íconos, campos y elementos secundarios.
    static let iconTile = Color(light: 0xEEF0F4, dark: 0x22302C)


    // MARK: - Alias compatibles con el código existente

    /// Alias del color principal.
    static let appPrimary = brand

    /// Alias del color secundario.
    static let appSecondary = brandTeal

    /// Alias del color terciario.
    static let appTertiary = brandGold
}


// MARK: - Color hexadecimal con soporte claro/oscuro

extension Color {

    /// Crea un color que cambia automáticamente
    /// dependiendo del modo claro u oscuro del sistema.
    ///
    /// Los valores deben estar en formato:
    /// 0xRRGGBB
    init(light: UInt32, dark: UInt32) {
        self.init(
            uiColor: UIColor { traits in
                UIColor(
                    hex: traits.userInterfaceStyle == .dark
                    ? dark
                    : light
                )
            }
        )
    }
}


// MARK: - UIColor hexadecimal

private extension UIColor {

    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
