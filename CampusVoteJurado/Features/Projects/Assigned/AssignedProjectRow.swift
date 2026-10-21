import SwiftUI

struct AssignedProjectRow: View {
    @Environment(\.locale) private var locale
    let project: ReviewProject
    let onTap: () -> Void

    private let naranja = Color(red: 0.85, green: 0.45, blue: 0.12)
    private let verde = Color(red: 0.13, green: 0.62, blue: 0.36)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    if let category = project.categoryName, !category.isEmpty {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(Color.appNeutral)
                    }
                }

                Spacer(minLength: 8)

                Text(L10n.tr(project.sinResena ? "Pendiente" : "Evaluado", locale: locale))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(project.sinResena ? naranja : verde)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill((project.sinResena ? naranja : verde).opacity(0.14)))

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appNeutral.opacity(0.6))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
        }
        .buttonStyle(.plain)
    }
}
