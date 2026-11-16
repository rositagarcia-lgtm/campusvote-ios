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
                    .frame(height: 260)
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
        .frame(height: 260)
        .clipShape(Rectangle())
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
            .background(Capsule().fill(Color.black.opacity(0.55)))
            .padding(12)
            .allowsHitTesting(false)
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
