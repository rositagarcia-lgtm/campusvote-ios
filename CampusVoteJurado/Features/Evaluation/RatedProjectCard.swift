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
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                        Text("Evaluado")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(Color(red: 0.13, green: 0.62, blue: 0.36))

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
                Text("Editar reseña >")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
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
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }
}
