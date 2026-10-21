import SwiftUI

struct MyProgressSummaryCard: View {
    @Environment(\.locale) private var locale
    let fairName: String
    let institutionName: String
    let ratedCount: Int
    let totalCount: Int
    let pendingCount: Int
    let fraction: Double
    let percent: Int
    let averageText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                progressRing

                VStack(alignment: .leading, spacing: 8) {
                    Text(fairName.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .lineLimit(2)

                    Text("Reseñas de proyectos")
                        .font(.subheadline.weight(.semibold))

                    statusPill(
                        text: ratedCount == 1
                            ? L10n.tr("1 completado", locale: locale)
                            : L10n.format("%d completados", locale: locale, ratedCount),
                        color: Color.appSuccess
                    )
                    statusPill(
                        text: pendingCount == 1
                            ? L10n.tr("1 reseña pendiente", locale: locale)
                            : L10n.format("%d reseñas pendientes", locale: locale, pendingCount),
                        color: Color.appWarning
                    )
                }
            }

            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Color.brandGold)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(averageText)
                            .font(.subheadline.weight(.semibold))
                        Text("promedio de estrellas\notorgadas")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(institutionName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("Jurados")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.brand.opacity(0.1)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSurface()
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.brand.opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.brand, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(ratedCount)/\(totalCount)")
                    .font(.caption.weight(.semibold))
                Text("\(percent)%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 64, height: 64)
    }

    private func statusPill(text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.12)))
    }
}
