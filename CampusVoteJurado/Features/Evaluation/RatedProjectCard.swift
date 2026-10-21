import SwiftUI

struct RatedProjectCard: View {
    let project: ReviewProject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    StatusBadge(title: "Evaluado", style: .reviewed)

                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let category = project.categoryName, !category.isEmpty {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 6) {
                if let rating = project.myRating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(star <= rating ? Color.brandGold : Color.appNeutral)
                        }
                    }
                    Text(String(format: "%.1f", Double(rating)))
                        .font(.caption.weight(.semibold))
                }
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Text("Editar reseña")
                    Image(systemName: "chevron.right")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            }

            if let comment = project.myComment, !comment.isEmpty {
                Text("\"\(comment)\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSurface()
    }
}
