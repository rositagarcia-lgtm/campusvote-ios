import SwiftUI

/// Video del prototipo dentro de la ficha. Agrandar lo pasa a toda la pantalla.
struct ProjectVideoBlock: View {
    let url: URL
    let poster: String?
    @StateObject private var playback: ProjectVideoPlayback
    @State private var expanded = false

    init(url: URL, poster: String?) {
        self.url = url
        self.poster = poster
        _playback = StateObject(wrappedValue: ProjectVideoPlayback(url: url))
    }

    var body: some View {
        ZStack {
            if let player = playback.player {
                ProjectVideoSurface(player: player)
            } else {
                CoverImage(url: poster.flatMap(URL.init(string:)))
            }
            ProjectVideoChrome(playback: playback, expanded: false) {
                playback.start()
                expanded = true
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .fullScreenCover(isPresented: $expanded) {
            ProjectVideoScreen(playback: playback) {
                expanded = false
            }
            .presentationBackground(.black)
        }
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
                    .foregroundStyle(.primary)
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
