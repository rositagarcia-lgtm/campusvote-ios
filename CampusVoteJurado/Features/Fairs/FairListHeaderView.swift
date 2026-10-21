import SwiftUI

struct FairListHeaderView: View {
    @Environment(\.locale) private var locale
    let institutionName: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                logo
                VStack(alignment: .leading, spacing: 4) {
                    Text(institutionName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.onBrand)
                        .lineLimit(1)
                    if let kind = InstitutionAppearance.kindLabel, !kind.isEmpty {
                        Text(L10n.tr(kind, locale: locale))
                            .font(.subheadline)
                            .foregroundStyle(Color.onBrand.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)

            Rectangle()
                .fill(Color.onBrand.opacity(0.2))
                .frame(height: 1)
        }
        .background {
            Color.brand
                .ignoresSafeArea(edges: .top)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 200, height: 200)
                        .offset(x: 60, y: -60)
                }
        }
    }

    private var logo: some View {
        Group {
            if let url = InstitutionAppearance.logoURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        ProgressView().tint(Color.brand)
                    }
                }
            } else {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.brand)
            }
        }
        .frame(width: 48, height: 48)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.onBrand))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
