import SwiftUI

struct LoginHeader: View {
    @Environment(\.locale) private var locale
    let accessType: JuryAccessType
    let showContent: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image("logo_campusvote")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1.0 : 0.9)
                .blur(radius: showContent ? 0 : 8)

            Text(L10n.tr(accessType.subtitle, locale: locale))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.campusGreen.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
        }
    }
}
