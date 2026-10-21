import SwiftUI
import UIKit

struct ProfileHeaderView: View {
    let greetingName: String
    let localAvatar: UIImage?
    let avatarURL: URL?
    let initials: String
    let onAvatarTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("¡Hola!")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                if !greetingName.isEmpty {
                    Text(greetingName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onAvatarTap) {
                ZStack(alignment: .bottomTrailing) {
                    avatarFace
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.cardBackground, lineWidth: 3))

                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 26, height: 26)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.brand)
                        }
                        .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cambiar foto de perfil")
        }
    }

    @ViewBuilder
    private var avatarFace: some View {
        if let localAvatar {
            Image(uiImage: localAvatar)
                .resizable()
                .scaledToFill()
        } else if let avatarURL {
            AsyncImage(url: avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                initialsFace
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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
            }
    }
}
