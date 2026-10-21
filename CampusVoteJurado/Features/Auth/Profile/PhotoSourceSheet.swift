import SwiftUI
import UIKit

struct PhotoSourceSheet: View {
    @Environment(\.locale) private var locale
    let avatar: UIImage?
    let avatarURL: URL?
    let initials: String
    let onClose: () -> Void
    let onCamera: () -> Void
    let onGallery: () -> Void
    let onDelete: () -> Void

    private let deleteColor = Color(red: 0.86, green: 0.18, blue: 0.38)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SheetTopBar(title: "Edición de foto", onClose: onClose)

            preview
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)

            photoRow(icon: "camera", title: "Tomar una foto", color: .primary, action: onCamera)
            photoRow(icon: "photo", title: "Elegir de la galería", color: .primary, action: onGallery)

            Divider().padding(.horizontal, 22)

            photoRow(icon: "trash", title: "Eliminar foto", color: deleteColor, action: onDelete)
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            Color.cardBackground
                .ignoresSafeArea(edges: .bottom)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
            )
        )
    }

    private var preview: some View {
        Group {
            if let avatar {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
            } else if let avatarURL {
                AsyncImage(url: avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsPreview
                }
            } else {
                initialsPreview
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.brand.opacity(0.2), lineWidth: 3))
        .accessibilityLabel("Vista previa de foto de perfil")
    }

    private var initialsPreview: some View {
        Circle()
            .fill(Color.brand)
            .overlay {
                Text(initials)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
            }
    }

    private func photoRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.08)))
                Text(L10n.tr(title, locale: locale))
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
