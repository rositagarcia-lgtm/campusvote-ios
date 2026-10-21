import SwiftUI

/// Portada del proyecto desde su URL, con un marcador mientras carga o si no tiene.
struct CoverImage: View {
    let url: URL?

    @ViewBuilder
    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    placeholder {
                        ProgressView()
                            .controlSize(.small)
                    }
                case .failure:
                    placeholder {
                        Image(systemName: "photo.badge.exclamationmark")
                            .foregroundStyle(.secondary)
                    }
                @unknown default:
                    placeholder {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            placeholder {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Sin imagen de portada")
            }
        }
    }

    private func placeholder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Rectangle()
            .fill(Color.iconTile)
            .overlay {
                content()
            }
    }
}
