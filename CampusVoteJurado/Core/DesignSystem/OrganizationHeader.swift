import SwiftUI

struct OrganizationLogo: View {
    var body: some View {
        AsyncImage(url: InstitutionAppearance.logoURL) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                Image("logo_campusvote").resizable().scaledToFit()
            }
        }
        .padding(4)
        .frame(width: 48, height: 48)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}

struct OrganizationHeader: View {
    let title: String
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 12) {
            OrganizationLogo()
            VStack(alignment: .leading, spacing: 4) {
                Text(InstitutionAppearance.name ?? "CampusVote")
                    .font(.headline)
                Text(L10n.tr(title, locale: locale))
                    .font(.subheadline)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.onBrand)
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, AppSpacing.standard)
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }
}
