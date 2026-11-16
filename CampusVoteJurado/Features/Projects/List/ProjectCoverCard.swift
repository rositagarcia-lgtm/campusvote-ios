import SwiftUI

struct ProjectCoverCard: View {
    @Environment(\.locale) private var locale
    let project: ReviewProject

    private var pending: Bool { project.sinResena }

    private var pillText: String {
        pending ? "Pendiente" : "Reseñado"
    }

    private var pillColor: Color {
        pending ? Color(red: 0.86, green: 0.42, blue: 0.10) : Color.appSuccess
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                .frame(maxWidth: .infinity)
                .frame(height: 176)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    Text(L10n.tr(pillText, locale: locale))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(pillColor))
                        .padding(10)
                }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if let category = project.categoryName, !category.isEmpty {
                        Text(category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .premiumSurface()
    }
}
