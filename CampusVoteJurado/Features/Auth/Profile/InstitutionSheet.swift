import SwiftUI
import UIKit

struct InstitutionSheet: View {
    @Environment(\.locale) private var locale
    let code: String
    let name: String
    let site: String
    let badge: String?
    let onClose: () -> Void
    @State private var copied = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Institución")
                            .font(.subheadline.weight(.semibold))
                        Text("Información y sede asignada para evaluación")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.trailing, 36)

                    infoCard(icon: "person.text.rectangle", title: "Código institucional", value: code) {
                        if code != "—" {
                            Button {
                                UIPasteboard.general.string = code
                                copied = true
                            } label: {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.brand)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Copiar código")
                        }
                    }

                    infoCard(icon: "graduationcap", title: "Nombre de la IE", value: name) {
                        if let badge {
                            Text(L10n.tr(badge, locale: locale))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.cardBackground))
                        }
                    }

                    infoCard(icon: "mappin.and.ellipse", title: "Sede", value: site) {
                        Image(systemName: "mappin.and.ellipse")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 20)
                            .foregroundStyle(Color.brand)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                Spacer(minLength: 12)
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .padding(.trailing, 6)
            .accessibilityLabel("Cerrar")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
            )
        )
    }

    private func infoCard<Accessory: View>(
        icon: String,
        title: String,
        value: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 20)
                .foregroundStyle(Color.brand)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.brand.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr(title, locale: locale))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
            accessory()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))
    }
}
