import SwiftUI
import UIKit

enum InstitutionAppearance {
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

    static var brandTeal: Color {
        if let hex = InstitutionAppearance.secondaryHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        return campusTeal
    }

    static let brandGold = Color(light: 0xD4AF37, dark: 0xE0C060)
    static let appNeutral = Color(light: 0x8E8E93, dark: 0x98989F)
    static let onBrand = Color(light: 0xFFFFFF, dark: 0x0E1514)
    static var appPrimaryLight: Color { brand.opacity(0.12) }
    static let appTertiaryLight = Color(light: 0xD4AF37, dark: 0xE0C060).opacity(0.20)
    static let brandMint = Color(light: 0xD9F3EE, dark: 0x1B3A35)
    static let appBackground = Color(light: 0xF7F8FC, dark: 0x0E1514)
    static let cardBackground = Color(light: 0xFFFFFF, dark: 0x16211F)
    static let iconTile = Color(light: 0xEEF0F4, dark: 0x22302C)
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
