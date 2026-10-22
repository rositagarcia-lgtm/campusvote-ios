import SwiftUI
import UIKit

enum InstitutionAppearance {
    /// Tinta oscura usada como texto sobre fondos claros de marca.
    private static let inkHex = "#0E1514"

    private static let state = InstitutionBrandState()

    static var name: String? {
        get { state.name }
        set { state.name = newValue }
    }
    static var kindLabel: String? {
        get { state.kindLabel }
        set { state.kindLabel = newValue }
    }
    static var logoURL: URL? {
        get { state.logoURL }
        set { state.logoURL = newValue }
    }
    static var primaryHex: String? {
        get { state.primaryHex }
        set { state.primaryHex = newValue }
    }
    static var secondaryHex: String? {
        get { state.secondaryHex }
        set { state.secondaryHex = newValue }
    }

    static func apply(_ brand: OrganizationBrand) {
        let cleanedName = brand.name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = cleanedName.isEmpty ? nil : cleanedName
        kindLabel = brand.kindLabel
        primaryHex = readableAccent(brand.primaryColor)
        secondaryHex = readableAccent(brand.secondaryColor)
        if let logo = brand.logo, let url = URL(string: logo),
           ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
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

    /// Acentos legibles sobre superficies claras, también si la marca es casi blanca.
    private static func readableAccent(_ hex: String?) -> String? {
        guard let hex, let rgb = rgbComponents(of: hex) else { return nil }
        var factor = 1.0
        var candidate = String(format: "#%02X%02X%02X", Int(rgb.r * 255), Int(rgb.g * 255), Int(rgb.b * 255))
        while contrastRatio(brandHex: candidate, textHex: "#FFFFFF") < 4.5 && factor > 0.1 {
            factor -= 0.05
            candidate = String(format: "#%02X%02X%02X", Int(rgb.r * factor * 255),
                               Int(rgb.g * factor * 255), Int(rgb.b * factor * 255))
        }
        return candidate
    }

    static func accentColor(_ hex: String, foreground: Bool = false) -> Color {
        Color(uiColor: UIColor { traits in
            guard let rgb = rgbComponents(of: hex) else { return .systemTeal }
            var channels = rgb
            if traits.userInterfaceStyle == .dark {
                var mix = 0.0
                while contrastRatio(brandHex: hexString(channels), textHex: "#16211F") < 4.5 && mix < 1 {
                    mix += 0.05
                    channels = (rgb.r + (1 - rgb.r) * mix, rgb.g + (1 - rgb.g) * mix,
                                rgb.b + (1 - rgb.b) * mix)
                }
            }
            if foreground {
                return contrastRatio(brandHex: hexString(channels), textHex: inkHex)
                    > contrastRatio(brandHex: hexString(channels), textHex: "#FFFFFF")
                    ? UIColor(red: 14 / 255, green: 21 / 255, blue: 20 / 255, alpha: 1) : .white
            }
            return UIColor(red: CGFloat(channels.r), green: CGFloat(channels.g), blue: CGFloat(channels.b), alpha: 1)
        })
    }

    private static func hexString(_ rgb: (r: Double, g: Double, b: Double)) -> String {
        String(format: "#%02X%02X%02X", Int(min(rgb.r, 1) * 255), Int(min(rgb.g, 1) * 255), Int(min(rgb.b, 1) * 255))
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

    /// El secundario comparte el ajuste de contraste del primario.
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
        let scanner = Scanner(string: clean)
        guard scanner.scanHexInt64(&value), scanner.isAtEnd else { return nil }

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
            return InstitutionAppearance.accentColor(hex)
        }
        return campusGreen
    }

    /// Acento secundario con contraste; CampusVote si no hay marca.
    static var brandTeal: Color {
        if let hex = InstitutionAppearance.institutionalSecondaryHex() {
            return InstitutionAppearance.accentColor(hex)
        }
        return campusTeal
    }

    static let brandGold = Color(light: 0xD4AF37, dark: 0xE0C060)
    static let appNeutral = Color(light: 0x61656D, dark: 0xADB6B2)
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
        return InstitutionAppearance.accentColor(hex, foreground: true)
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
