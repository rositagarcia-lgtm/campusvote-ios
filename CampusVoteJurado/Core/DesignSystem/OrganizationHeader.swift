import SwiftUI
import UIKit

@MainActor
@Observable
final class LogoMemory {
    static let shared = LogoMemory()
    var images: [URL: UIImage] = [:]
}

struct OrganizationLogo: View {
    @State private var memory = LogoMemory.shared

    private var url: URL? { InstitutionAppearance.logoURL }

    private var ready: UIImage? {
        guard let url else { return nil }
        return memory.images[url]
    }

    var body: some View {
        Group {
            if let ready {
                Image(uiImage: ready).resizable().scaledToFit()
            } else if url == nil {
                Image("logo_campusvote").resizable().scaledToFit()
            } else {
                Color.clear
            }
        }
        .padding(4)
        .frame(width: 38, height: 38)
        .accessibilityHidden(true)
        .task(id: url) {
            guard let url else { return }
            if memory.images[url] != nil { return }
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode ?? 500 < 400,
                  let downloaded = UIImage(data: data) else { return }
            memory.images[url] = downloaded
        }
    }
}

struct OrganizationHeader: View {
    let title: String
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 12) {
            OrganizationLogo()
            VStack(alignment: .leading, spacing: 2) {
                Text(InstitutionAppearance.name ?? "CampusVote")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(L10n.tr(title, locale: locale))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HeaderBell()
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, 10)
        .frame(minHeight: 68)
        .background(Color.cardBackground.ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.brand)
                .frame(height: 2)
        }
    }
}

private struct HeaderAvatar: View {
    @Environment(SessionStore.self) private var session
    @State private var portrait = PortraitStore.shared

    var body: some View {
        avatar
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .accessibilityLabel("Foto de perfil")
            .task { await reload() }
    }

    @ViewBuilder
    private var avatar: some View {
        if portrait.hidden {
            initialsFace
        } else if let local = portrait.local {
            Image(uiImage: local).resizable().scaledToFill()
        } else if let remoteURL = portrait.remoteURL {
            AsyncImage(url: remoteURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    initialsFace
                }
            }
        } else {
            initialsFace
        }
    }

    private var initialsFace: some View {
        Circle()
            .fill(Color.brand)
            .overlay {
                Text(initials)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.onBrand)
            }
    }

    private var initials: String {
        guard case .signedIn(let user) = session.phase else { return "?" }
        let first = user.firstName.first.map(String.init) ?? ""
        let last = user.lastName.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "?" : value
    }

    @MainActor
    private func reload() async {
        guard case .signedIn(let user) = session.phase else { return }
        portrait.hidden = ProfileAvatarStore.isHidden(for: user.id)
        portrait.local = ProfileAvatarStore.load(for: user.id)
        guard !portrait.hidden, portrait.local == nil, portrait.remoteURL == nil else { return }
        portrait.remoteURL = await HeaderAvatarLoader.remoteURL()
    }
}

@MainActor
@Observable
final class PortraitStore {
    static let shared = PortraitStore()
    var local: UIImage?
    var remoteURL: URL?
    var hidden = false
}

@MainActor
private enum HeaderAvatarLoader {
    private static var task: Task<URL?, Never>?

    static func remoteURL() async -> URL? {
        if let task { return await task.value }
        let created = Task { () -> URL? in
            let profile = try? await APIClient.shared.send(
                Endpoint(path: "users/me", method: "GET"),
                as: JuryProfile.self
            )
            return profile?.avatarURL
        }
        task = created
        return await created.value
    }
}
