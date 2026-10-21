import SwiftUI

struct AssignedProjectRow: View {
    @Environment(\.locale) private var locale
    let project: ReviewProject
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    if let category = project.categoryName, !category.isEmpty {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(Color.appNeutral)
                    }
                }

                Spacer(minLength: 8)

                StatusBadge(
                    title: project.sinResena ? "Pendiente" : "Evaluado",
                    style: project.sinResena ? .pending : .reviewed
                )

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appNeutral.opacity(0.6))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .premiumSurface(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }
}
