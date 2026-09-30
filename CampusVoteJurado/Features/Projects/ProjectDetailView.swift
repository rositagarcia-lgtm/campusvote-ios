import SwiftUI
import UIKit

/// Detalle del proyecto: logo, título y el material que subieron.
struct ProjectDetailView: View {
    let fairId: String
    let projectId: String
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(TabBarVisibility.self) private var tabBar

    @State private var detail: ProjectDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var photoIndex = 0
    @State private var photoExpanded = false

    private let api = APIClient.shared

    var body: some View {
        VStack(spacing: 0) {
            encabezado

            if isLoading && detail == nil {
                ProgressView("Cargando proyecto...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let errorMessage {
                            ErrorBanner(message: errorMessage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        identidad(detail)
                            .padding(.horizontal, 16)

                        let fotos = material(detail)
                        if !fotos.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Material")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 16)
                                galeria(fotos)
                            }
                        }

                        if let video = detail.videoUrl, let url = URL(string: video) {
                            videoCard(url, poster: fotos.first)
                                .padding(.horizontal, 16)
                        }

                        if let description = detail.description, !description.isEmpty {
                            bloque("Resumen") {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 16)
                        }

                        if !detail.members.isEmpty {
                            bloque("Integrantes") {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(detail.members) { member in
                                        integrante(member)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if let raw = detail.projectUrl, let url = URL(string: raw) {
                            enlace(url, titulo: "Abrir el proyecto", icono: "link")
                                .padding(.horizontal, 16)
                        }

                        ProjectVotePanel(fairId: fairId, projectId: projectId)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .overlay {
            if photoExpanded, let fotos = detail.map(material), !fotos.isEmpty {
                PhotoViewer(urls: fotos, index: $photoIndex) {
                    photoExpanded = false
                }
            }
        }
        .onChange(of: photoExpanded) { _, abierto in
            tabBar.isHidden = abierto
        }
        .onDisappear {
            tabBar.isHidden = false
        }
        .task { await load() }
    }

    private var encabezado: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Proyecto")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.onBrand)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Volver")
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.onBrand.opacity(0.35))
                .frame(height: 0.5)
        }
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

    private func identidad(_ detail: ProjectDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                logo(detail.logoUrl)

                Text(detail.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                if let stand = detail.standCode, !stand.isEmpty {
                    Label("Stand \(stand)", systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let category = detail.categoryName, !category.isEmpty {
                    Text(category)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.brand.opacity(0.12)))
                }
            }

            if !detail.members.isEmpty {
                let cantidad = detail.members.count
                Label(
                    cantidad == 1 ? "1 integrante" : "\(cantidad) integrantes",
                    systemImage: "person.2"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func logo(_ raw: String?) -> some View {
        let url = raw.flatMap { URL(string: $0) }
        return AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .font(.body)
                    .foregroundStyle(Color.brand)
            }
        }
        .padding(6)
        .frame(width: 56, height: 56)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.08)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func galeria(_ fotos: [String]) -> some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $photoIndex) {
                ForEach(Array(fotos.enumerated()), id: \.offset) { index, url in
                    CoverImage(url: URL(string: url))
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            photoIndex = index
                            photoExpanded = true
                        }
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 230)

            if fotos.count > 1 {
                Text("\(photoIndex + 1) / \(fotos.count) fotos")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.black.opacity(0.55)))
                    .padding(10)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private func videoCard(_ url: URL, poster: String?) -> some View {
        Link(destination: url) {
            ZStack {
                CoverImage(url: poster.flatMap { URL(string: $0) })
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipped()

                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                    Text("Ver video")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func bloque(_ titulo: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titulo)
                .font(.subheadline.weight(.semibold))
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func enlace(_ url: URL, titulo: String, icono: String) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: icono)
                    .font(.body)
                    .foregroundStyle(Color.brand)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.12)))
                Text(titulo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func integrante(_ member: ProjectDetail.Member) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .font(.body)
                .foregroundStyle(Color.brand)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(member.firstName ?? "") \(member.lastName ?? "")".trimmingCharacters(in: .whitespaces))
                    .font(.subheadline.weight(.semibold))
                if let role = member.role, !role.isEmpty {
                    Text(role)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    /// Fotos que subió el proyecto. El logo no entra aquí.
    private func material(_ detail: ProjectDetail) -> [String] {
        var urls: [String] = []
        func add(_ url: String?) {
            guard let url, !url.isEmpty, url != detail.logoUrl, !urls.contains(url) else { return }
            urls.append(url)
        }
        detail.imageUrls.forEach { add($0) }
        add(detail.coverUrl)
        return urls
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            detail = try await api.send(
                Endpoint.projectDetail(fairId: fairId, projectId: projectId),
                as: ProjectDetail.self
            )
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Foto a pantalla completa

private struct PhotoViewer: View {
    let urls: [String]
    @Binding var index: Int
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(urls.enumerated()), id: \.offset) { offset, url in
                    ZoomableRemoteImage(urlString: url)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.22)))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar")

                Spacer()

                if urls.count > 1 {
                    Text("\(index + 1) / \(urls.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .zIndex(10)
        }
    }
}

private struct ZoomableRemoteImage: View {
    let urlString: String
    @State private var scale: CGFloat = 1

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView().tint(.white)
            }
        }
        .scaleEffect(scale)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = min(max(value, 1), 4)
                }
                .onEnded { _ in
                    if scale < 1.05 { scale = 1 }
                }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Un voto por jurado en toda la feria. No muestra cuál proyecto eligió.
struct ProjectVotePanel: View {
    let fairId: String
    let projectId: String

    @Environment(FairsStore.self) private var fairs
    @State private var hasVoted = false
    @State private var receipt: String?
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var confirm = false

    private var fairIsReady: Bool {
        guard let fair = (fairs.activeFairs + fairs.closedFairs).first(where: { $0.fair.id == fairId })?.fair else {
            return true
        }
        guard fair.isOpen else { return false }
        guard let startsAt = fair.startsAt else { return true }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        guard let date = parser.date(from: startsAt) ?? plain.date(from: startsAt) else { return true }
        return date <= Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Voto de la feria")
                .font(.subheadline.weight(.semibold))

            if hasVoted {
                Label("Tu voto en esta feria ya fue emitido.", systemImage: "checkmark.seal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if fairIsReady {
                Text("Es uno solo para toda la feria y no depende de la rúbrica.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Elegir como mi voto") { confirm = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isWorking)
            } else {
                Text("El voto se habilita cuando la feria está abierta.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .task { await loadStatus() }
        .confirmationDialog(
            "Este voto es uno solo para toda la feria.",
            isPresented: $confirm,
            titleVisibility: .visible
        ) {
            Button("Emitir voto") { Task { await cast() } }
            Button("Cancelar", role: .cancel) {}
        }
        .alert("Comprobante", isPresented: Binding(
            get: { receipt != nil },
            set: { if !$0 { receipt = nil } }
        )) {
            Button("Copiar") {
                if let receipt {
                    UIPasteboard.general.string = receipt
                }
            }
            Button("Listo", role: .cancel) {}
        } message: {
            Text("Guárdalo ahora: \(receipt ?? ""). No se vuelve a mostrar.")
        }
    }

    private func loadStatus() async {
        guard let status = try? await APIClient.shared.send(
            .votingStatus(fairId: fairId),
            as: VotingStatus.self
        ) else { return }
        hasVoted = status.hasVoted
    }

    private func cast() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let result = try await APIClient.shared.send(
                .castVote(fairId: fairId, projectId: projectId),
                as: VoteReceipt.self
            )
            receipt = result.receiptCode
            hasVoted = true
        } catch {
            errorMessage = error.userMessage
        }
    }
}
