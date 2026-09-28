import SwiftUI

enum JuryTheme {
    static var brand: Color { Color.brand }
    static var brandDeep: Color { Color.brand }
    static let mint = Color(red: 0.843, green: 0.961, blue: 0.925)
    static var mintText: Color { Color.brand }
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let goldDeep = Color(red: 0.72, green: 0.56, blue: 0.12)
    static let surface = Color(.systemGray6)
    static var accent: Color { .accentColor }
}

extension Color {
    static var juryBrand: Color { JuryTheme.brand }
    static var juryMint: Color { JuryTheme.mint }
}

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
