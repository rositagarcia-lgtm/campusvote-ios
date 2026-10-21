import SwiftUI

/// Banner con las fotos del proyecto y su contador.
struct ProjectGalleryBanner: View {
    let urls: [String]
    @Binding var page: Int
    let onSelect: (Int) -> Void

    var body: some View {
        TabView(selection: $page) {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                CoverImage(url: URL(string: url))
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(index)
                    }
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.caption2.weight(.semibold))
                Text("\(min(page + 1, urls.count))/\(urls.count)")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .padding(12)
            .allowsHitTesting(false)
        }
    }
}

/// Título del proyecto con su logo y categoría.
struct ProjectIdentityRow: View {
    let detail: ProjectDetail

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let logo = detail.logoUrl {
                ProjectLogoMark(urlString: logo)
            }

            Text(detail.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            if let category = detail.categoryName, !category.isEmpty {
                Text(category)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
        }
    }
}

/// Logo cuadrado del proyecto.
struct ProjectLogoMark: View {
    let urlString: String

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 8).fill(Color.brand.opacity(0.12))
            }
        }
        .padding(4)
        .frame(width: 36, height: 36)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08)))
    }
}
