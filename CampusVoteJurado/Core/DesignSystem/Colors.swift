import SwiftUI
import UIKit

enum InstitutionAppearance {
    /// Tinta oscura usada como texto sobre fondos claros de marca.
    private static let inkHex = "#0E1514"

    static var name: String?
    static var kindLabel: String?
    static var logoURL: URL?
    static var primaryHex: String?
    static var secondaryHex: String?

    static func apply(_ brand: OrganizationBrand) {
        name = brand.name
        kindLabel = brand.kindLabel
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
        kindLabel = nil
        logoURL = nil
        primaryHex = nil
        secondaryHex = nil
    }

    /// El color de texto sobre la marca debe elegirse por contraste real.
    /// Si la institución usa un color claro (celeste, amarillo, etc.), el
    /// blanco desaparece; en ese caso usamos tinta oscura.
    static var prefersDarkTextOnBrand: Bool {
        guard let hex = primaryHex, !hex.isEmpty else {
            return false
        }
        return contrastRatio(brandHex: hex, textHex: inkHex)
            > contrastRatio(brandHex: hex, textHex: "#FFFFFF")
    }

    /// Contraste (WCAG) entre el color de marca y un color de texto.
    static func contrastRatio(brandHex: String, textHex: String) -> Double {
        guard let brand = relativeLuminance(of: brandHex),
              let text = relativeLuminance(of: textHex) else {
            return 1
        }
        let lighter = max(brand, text)
        let darker = min(brand, text)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// El color secundario de la institución se usa tal cual lo define la
    /// organización: nunca se mezcla con negro ni se oscurece.
    static func institutionalSecondaryHex() -> String? {
        guard let secondary = secondaryHex, !secondary.isEmpty else { return nil }
        return secondary
    }

    static func relativeLuminance(of hex: String) -> Double? {
        guard let rgb = rgbComponents(of: hex) else { return nil }

        func linear(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linear(rgb.r) + 0.7152 * linear(rgb.g) + 0.0722 * linear(rgb.b)
    }

    private static func rgbComponents(of hex: String) -> (r: Double, g: Double, b: Double)? {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard Scanner(string: clean).scanHexInt64(&value) else { return nil }

        let r, g, b: UInt64
        switch clean.count {
        case 3:
            r = (value >> 8 & 0xF) * 17
            g = (value >> 4 & 0xF) * 17
            b = (value & 0xF) * 17
        case 6:
            r = value >> 16 & 0xFF
            g = value >> 8 & 0xFF
            b = value & 0xFF
        case 8:
            r = value >> 24 & 0xFF
            g = value >> 16 & 0xFF
            b = value >> 8 & 0xFF
        default:
            return nil
        }

        return (
            Double(r) / 255,
            Double(g) / 255,
            Double(b) / 255
        )
    }
}

extension Color {
    static let campusGreen = Color(light: 0x004D40, dark: 0x4DB6AC)
    static let campusTeal = Color(light: 0x00695C, dark: 0x80CBC4)

    static var brand: Color {
        if let hex = InstitutionAppearance.primaryHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        return campusGreen
    }

    /// Color secundario de la institución, tal como lo entrega el backend.
    /// Sin marca institucional se usa el verde azulado de CampusVote.
    static var brandTeal: Color {
        if let hex = InstitutionAppearance.institutionalSecondaryHex() {
            return Color(hex: hex)
        }
        return campusTeal
    }

    static let brandGold = Color(light: 0xD4AF37, dark: 0xE0C060)
    static let appNeutral = Color(light: 0x8E8E93, dark: 0x98989F)
    static let appSuccess = Color(light: 0x167747, dark: 0x69DB9B)
    static let appWarning = Color(light: 0x9A4B0B, dark: 0xFFB466)
    static let appDanger = Color(light: 0xB42318, dark: 0xFF8A80)

    /// Texto/iconos sobre `brand`. Con marca institucional clara usa tinta
    /// oscura; con marca oscura usa blanco. Sin marca institucional conserva
    /// el comportamiento adaptativo original.
    static var onBrand: Color {
        guard let hex = InstitutionAppearance.primaryHex, !hex.isEmpty else {
            return Color(light: 0xFFFFFF, dark: 0x0E1514)
        }
        return InstitutionAppearance.prefersDarkTextOnBrand
            ? Color(light: 0x0E1514, dark: 0x0E1514)
            : Color(light: 0xFFFFFF, dark: 0xFFFFFF)
    }
    static var appPrimaryLight: Color { brand.opacity(0.12) }
    static let appTertiaryLight = Color(light: 0xD4AF37, dark: 0xE0C060).opacity(0.20)
    static let brandMint = Color(light: 0xD9F3EE, dark: 0x1B3A35)
    static let appBackground = Color(light: 0xF7F8FC, dark: 0x0E1514)
    static let cardBackground = Color(light: 0xFFFFFF, dark: 0x16211F)
    static let iconTile = Color(light: 0xEEF0F4, dark: 0x22302C)
    static let cardBorder = Color(light: 0xE5E7EB, dark: 0x2B3936)
    static var appPrimary: Color { brand }
    static var appSecondary: Color { brandTeal }
    static var appTertiary: Color { brandGold }
}

extension Color {
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

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(
            uiColor: UIColor { traits in
                UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }
}

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
