import SwiftUI

struct ProjectCoverCard: View {
    @Environment(\.locale) private var locale
    let project: ReviewProject
    let naranja: Color
    let verde: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                .frame(maxWidth: .infinity)
                .frame(height: 188)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Text(L10n.tr(project.sinResena ? "Sin reseña" : "Con reseña", locale: locale))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(project.sinResena ? naranja : verde)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill((project.sinResena ? naranja : verde).opacity(0.14))
                        )
                }

                HStack(spacing: 6) {
                    if let category = project.categoryName, !category.isEmpty {
                        Text(category)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.primary.opacity(0.06)))
                    }
                    if let stand = project.standCode, !stand.isEmpty {
                        Text(stand)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.primary.opacity(0.06)))
                    }
                }

                if let team = project.teamName, !team.isEmpty {
                    Text(team)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(L10n.tr(project.sinResena ? "Reseña pendiente" : "Reseña enviada", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Ver proyecto")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSurface()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
