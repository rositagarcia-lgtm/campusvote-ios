import SwiftUI

struct ProfileFairCard: View {
    @Environment(\.locale) private var locale
    let fairName: String?
    let fairDate: String?
    let pendingLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("FERIA ASIGNADA")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(Color.white.opacity(0.8))
                Spacer(minLength: 8)
                if fairName != nil {
                    Text("Evaluando")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.brandGold))
                }
            }

            Text(fairName ?? L10n.tr("Sin feria activa", locale: locale))
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let fairDate {
                Label(fairDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            Text(fairName == nil ? L10n.tr("Cuando haya una feria abierta vas a ver tus proyectos aquí.", locale: locale) : pendingLine)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.brand)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "checklist")
                        .font(.system(size: 95, weight: .ultraLight))
                        .foregroundStyle(Color.white.opacity(0.12))
                        .offset(x: 8, y: 14)
                        .accessibilityHidden(true)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .shadow(color: Color.brand.opacity(0.14), radius: 12, y: 5)
    }
}

struct ProfileShortcutView: View {
    @Environment(\.locale) private var locale
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle")
                    .font(.title3)
                    .foregroundStyle(Color.brand)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.brand.opacity(0.1)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("Mis Datos", locale: locale))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(L10n.tr("Ver y editar información", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .frame(maxWidth: .infinity)
    }
}

struct ProfileProgressCard: View {
    @Environment(\.locale) private var locale
    let rated: Int
    let total: Int
    let progressValue: CGFloat
    let rubricLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.headline)
                    .foregroundStyle(Color.brand)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.brand.opacity(0.12)))
                Text("Completa tu evaluación")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(L10n.format("%d de %d", locale: locale, rated, total))
                        .font(.subheadline.weight(.semibold))
                    Text("proyectos calificados")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.12))
                    Capsule()
                        .fill(Color.brand)
                        .frame(width: geo.size.width * progressValue)
                }
            }
            .frame(height: 9)

            Text(rubricLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.brand.opacity(0.07))
        )
    }
}
