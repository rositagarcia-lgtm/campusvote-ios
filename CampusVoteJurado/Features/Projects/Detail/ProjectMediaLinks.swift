import SwiftUI

/// Bloque con el video del prototipo.
struct ProjectVideoBlock: View {
    @Environment(\.openURL) private var openURL
    let url: URL
    let poster: String?

    var body: some View {
        Button {
            openURL(url)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    CoverImage(url: poster.flatMap(URL.init(string:)))
                        .frame(maxWidth: .infinity)
                        .frame(height: 148)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Circle()
                        .fill(.white.opacity(0.94))
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.brand)
                                .offset(x: 1)
                        }
                }

                Text("Ver video del prototipo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Enlace externo del proyecto.
struct ProjectLinkRow: View {
    @Environment(\.openURL) private var openURL
    let url: URL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.brand.opacity(0.12)))

                Text(ProjectLinkRow.visibleText(for: url))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brand)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    static func visibleText(for url: URL) -> String {
        guard let host = url.host, !host.isEmpty else {
            return url.absoluteString
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
        }
        var text = host + url.path
        if text.hasSuffix("/") {
            text.removeLast()
        }
        if let query = url.query, !query.isEmpty {
            text += "?\(query)"
        }
        return text
    }
}
