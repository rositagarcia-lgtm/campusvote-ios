import SwiftUI

struct ProjectListFilterSheet: View {
    @Environment(\.locale) private var locale
    @Binding var draftStatus: StatusFilter
    let projects: [ReviewProject]
    let naranja: Color
    let verde: Color
    let onCancel: () -> Void
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.primary.opacity(0.16))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)

            HStack(alignment: .center, spacing: 8) {
                Text("Filtros")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Button {
                    draftStatus = .all
                } label: {
                    Text("Restablecer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar")
            }

            HStack {
                Text("ESTADO DE EVALUACIÓN")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text("Selecciona uno")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 10) {
                ForEach(StatusFilter.allCases) { item in
                    statusCard(item)
                }
            }

            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("Cancelar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onApply) {
                    HStack(spacing: 8) {
                        Text("Aplicar filtros")
                            .font(.subheadline.weight(.semibold))
                        Text("1")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.brand)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.onBrand))
                    }
                    .foregroundStyle(Color.onBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground.ignoresSafeArea(edges: .bottom))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
            )
        )
    }

    private func statusCard(_ item: StatusFilter) -> some View {
        let selected = draftStatus == item
        let tint = item.tint(brand: Color.brand, naranja: naranja, verde: verde)
        let total = count(item)

        return Button {
            draftStatus = item
        } label: {
            VStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                Text(L10n.tr(item.title, locale: locale))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(itemsLabel(total))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? Color.brand.opacity(0.08) : Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.brand : Color.primary.opacity(0.1), lineWidth: selected ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.brand)
                        .background(Circle().fill(Color.cardBackground))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func count(_ item: StatusFilter) -> Int {
        switch item {
        case .all:
            return projects.count
        case .pending:
            return projects.filter(\.sinResena).count
        case .rated:
            return projects.filter { !$0.sinResena }.count
        }
    }

    private func itemsLabel(_ total: Int) -> String {
        total == 1 ? L10n.tr("1 item", locale: locale) : L10n.format("%d items", locale: locale, total)
    }
}
