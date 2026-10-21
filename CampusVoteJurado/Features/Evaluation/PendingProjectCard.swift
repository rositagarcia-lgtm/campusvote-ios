import SwiftUI

struct PendingProjectCard: View {
    let project: ReviewProject

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let category = project.categoryName, !category.isEmpty {
                            Text(category.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        StatusBadge(title: "Pendiente", style: .pending)
                    }

                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
            }

            HStack {
                Text("Sin reseña aún")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                    Text("Evaluar")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.onBrand)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.brand))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSurface()
    }
}
