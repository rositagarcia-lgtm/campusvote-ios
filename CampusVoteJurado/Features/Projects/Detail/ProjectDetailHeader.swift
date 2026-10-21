import SwiftUI

/// Cabecera de la ficha de proyecto con la acción de volver.
struct ProjectDetailHeader: View {
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Text("Detalle de proyecto")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.trailing, 16)
    }
}

/// Tarjeta blanca usada por las secciones de la ficha.
struct ProjectDetailCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSurface()
    }
}

/// Rótulo de sección en mayúsculas.
struct ProjectDetailLabel: View {
    @Environment(\.locale) private var locale
    let title: String

    var body: some View {
        Text(L10n.tr(title, locale: locale))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}
