import SwiftUI

/// Ficha de solo lectura de un proyecto aprobado. Se usa para el listado
/// "Todos los proyectos" y para los QR que no están asignados al jurado.
struct PublicProjectView: View {
    @Environment(\.locale) private var locale
    let fairId: String?
    let projectId: String
    var fallback: Project? = nil

    @Environment(ProjectsCatalogStore.self) private var catalog
    @Environment(\.dismiss) private var dismiss

    @State private var project: PublicProject?
    @State private var basic: Project?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var name: String {
        project?.name ?? basic?.name ?? L10n.tr("Proyecto", locale: locale)
    }

    private var description: String? {
        let value = project?.description ?? basic?.description
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    private var coverUrl: String? {
        project?.coverUrl ?? basic?.coverUrl
    }

    private var logoUrl: String? {
        project?.logoUrl ?? basic?.logoUrl
    }

    private var categoryName: String? {
        project?.categoryName ?? basic?.categoryName
    }

    private var standCode: String? {
        project?.standCode ?? basic?.standCode
    }

    private var fairName: String? {
        project?.fairName
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView("Cargando proyecto...")
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    } else {
                        cover
                        identity
                        information
                    }
                }
                .padding(18)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Volver")

            VStack(alignment: .leading, spacing: 2) {
                Text("Detalle del proyecto")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)
                Text("Solo lectura")
                    .font(.caption)
                    .foregroundStyle(Color.onBrand.opacity(0.8))
            }

            Spacer(minLength: 0)

            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(Color.onBrand)
                .accessibilityLabel("Proyecto aprobado")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

    @ViewBuilder
    private var cover: some View {
        if let coverUrl, let url = URL(string: coverUrl) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Rectangle().fill(Color.cardBackground)
                        .overlay { ProgressView() }
                }
            }
            .frame(height: 190)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var identity: some View {
        HStack(alignment: .top, spacing: 12) {
            if let logoUrl, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.cardBackground
                    }
                }
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.primary)

                HStack(spacing: 6) {
                    badge(L10n.tr("Aprobado", locale: locale), color: .green)
                    if let categoryName {
                        badge(categoryName, color: .brand)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private var information: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let description {
                labeled("DESCRIPCIÓN", value: description)
            }

            if let fairName {
                labeled("FERIA", value: fairName)
            }

            if let organizationName = project?.organizationName {
                labeled("ORGANIZACIÓN", value: organizationName)
            }

            if let standCode {
                labeled("STAND", value: standCode)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func labeled(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.tr(title, locale: locale))
                .font(.system(size: 11, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Color.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        basic = fallback

        var resolvedFairId = fairId ?? fallback?.fairId ?? basic?.fairId
        if resolvedFairId == nil {
            let loaded = await catalog.project(id: projectId)
            basic = loaded
            resolvedFairId = loaded?.fairId
        }

        if let resolvedFairId {
            project = await catalog.publicProject(fairId: resolvedFairId, projectId: projectId)
        }

        if project == nil, basic == nil {
            errorMessage = "No se pudo cargar la información de este proyecto."
        }
    }
}
