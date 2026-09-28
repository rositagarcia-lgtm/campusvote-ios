import SwiftUI
import UIKit

/// Marca de la institución. Se aplica al entrar y se borra al salir.
/// El login no la consulta: sigue con los colores de CampusVote.
enum InstitutionAppearance {
    static var name: String?
    static var logoURL: URL?
    static var primaryHex: String?
    static var secondaryHex: String?

    static func apply(_ brand: OrganizationBrand) {
        name = brand.name
        primaryHex = brand.primaryColor
        secondaryHex = brand.secondaryColor
        if let logo = brand.logo, let url = URL(string: logo) {
            logoURL = url
        } else {
            logoURL = nil
        }
    }

    static func reset() {
        name = nil
        logoURL = nil
        primaryHex = nil
        secondaryHex = nil
    }
}

/// Colores de CampusVote.
/// Compatible con modo claro y oscuro.
extension Color {

    // MARK: - Colores principales

    /// Verde de CampusVote. La pantalla de entrar siempre usa este color.
    static let campusGreen = Color(light: 0x004D40, dark: 0x4DB6AC)

    /// Verde secundario de CampusVote, fijo, para el login y el código.
    static let campusTeal = Color(light: 0x00695C, dark: 0x80CBC4)

    /// Después de entrar, el primario de la institución. Antes, el de CampusVote.
    static var brand: Color {
        if let hex = InstitutionAppearance.primaryHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        return campusGreen
    }

    /// Después de entrar, el secundario de la institución.
    static var brandTeal: Color {
        if let hex = InstitutionAppearance.secondaryHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        return campusTeal
    }

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
    static var appPrimaryLight: Color { brand.opacity(0.12) }

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

    /// Alias del color principal. Sigue a la institución después del login.
    static var appPrimary: Color { brand }

    /// Alias del color secundario.
    static var appSecondary: Color { brandTeal }

    /// Alias del color terciario.
    static var appTertiary: Color { brandGold }
}

// MARK: - Color hexadecimal (#RRGGBB)

extension Color {
    /// Crea un color desde una cadena hexadecimal ("#7A5E0B", "7A5E0B", "RRGGBBAA").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        let r, g, b, a: UInt64
        switch hex.count {
        case 3:
            (r, g, b, a) = ((value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17, 255)
        case 6:
            (r, g, b, a) = (value >> 16, value >> 8 & 0xFF, value & 0xFF, 255)
        case 8:
            (r, g, b, a) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
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