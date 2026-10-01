import SwiftUI

struct ProjectDetailView: View {
    let fairId: String
    let projectId: String

    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairs
    @Environment(TabBarVisibility.self) private var tabBar
    @Environment(\.dismiss) private var dismiss

    @State private var detail: ProjectDetail?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var stars = 0
    @State private var comment = ""
    @State private var photoIndex: Int?
    @State private var savedNote = false

    private let api = APIClient.shared

    private var fairIsClosed: Bool {
        fairs.closedFairs.contains { $0.fair.id == fairId }
    }

    private var commentCount: Int {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var canSave: Bool {
        !fairIsClosed && !isSaving && (1...5).contains(stars) && (10...1000).contains(commentCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    if isLoading {
                        ProgressView("Cargando proyecto...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let detail {
                        titleBlock(detail)

                        if let description = detail.description, !description.isEmpty {
                            block("Descripción") {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }

                        let photos = materialURLs(for: detail)
                        if !photos.isEmpty {
                            block("Material") {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(photos.enumerated()), id: \.offset) { index, url in
                                            Button {
                                                photoIndex = index
                                            } label: {
                                                CoverImage(url: URL(string: url))
                                                    .frame(width: 148, height: 96)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        if let video = detail.videoUrl, let url = URL(string: video) {
                            linkRow(title: "Ver video", systemImage: "play.rectangle", url: url)
                        }

                        if let page = detail.projectUrl, let url = URL(string: page) {
                            linkRow(title: "Abrir el proyecto", systemImage: "link", url: url)
                        }

                        reviewCard
                    }
                }
                .padding(18)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await load()
        }
        .onChange(of: photoIndex) { _, index in
            tabBar.isHidden = index != nil
        }
        .onDisappear {
            tabBar.isHidden = false
        }
        .overlay {
            if let detail, let photoIndex {
                PhotoViewer(
                    urls: materialURLs(for: detail),
                    index: photoIndex,
                    onClose: { self.photoIndex = nil }
                )
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Detalle")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.onBrand)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(.horizontal, 8)

            Rectangle()
                .fill(Color.onBrand.opacity(0.35))
                .frame(height: 0.5)
        }
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

    private func titleBlock(_ detail: ProjectDetail) -> some View {
        HStack(alignment: .center, spacing: 12) {
            logo(detail.logoUrl)

            VStack(alignment: .leading, spacing: 4) {
                Text(detail.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let category = detail.categoryName, !category.isEmpty {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func logo(_ urlString: String?) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Color.brand.opacity(0.08)
                    }
                }
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(Color.brand)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.brand.opacity(0.08))
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func block(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func linkRow(title: String, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(Color.brand)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tu reseña")
                .font(.subheadline.weight(.semibold))

            if fairIsClosed {
                Text("Esta feria está cerrada.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        guard !fairIsClosed else { return }
                        stars = star
                        savedNote = false
                    } label: {
                        Image(systemName: star <= stars ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(star <= stars ? Color.brandGold : Color.appNeutral)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .disabled(fairIsClosed)
                }
            }

            ZStack(alignment: .topLeading) {
                if comment.isEmpty {
                    Text("Escribe un comentario")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                }
                TextEditor(text: $comment)
                    .font(.subheadline)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 110)
                    .padding(8)
                    .disabled(fairIsClosed)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.iconTile))
            .onChange(of: comment) { _, _ in
                savedNote = false
            }

            Text("\(commentCount)/1000")
                .font(.caption)
                .foregroundStyle((10...1000).contains(commentCount) ? Color.secondary : Color.brand)

            if savedNote {
                Text("Reseña guardada.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }

            Button {
                Task { await save() }
            } label: {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(Color.onBrand)
                    } else {
                        Text("Guardar reseña")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(Color.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(canSave ? 1 : 0.4)))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func materialURLs(for detail: ProjectDetail) -> [String] {
        var urls = detail.imageUrls.filter { $0 != detail.logoUrl }
        if let cover = detail.coverUrl, cover != detail.logoUrl, !urls.contains(cover) {
            urls.append(cover)
        }
        return urls
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await api.send(
                .projectDetail(fairId: fairId, projectId: projectId),
                as: ProjectDetail.self
            )
        } catch {
            errorMessage = error.userMessage
        }

        do {
            let loaded = try await api.send(
                .projectRating(fairId: fairId, projectId: projectId),
                as: ProjectRating.self
            )
            stars = loaded.rating ?? 0
            comment = loaded.comment ?? ""
        } catch let error as APIError {
            if case .decoding = error {
                stars = 0
                comment = ""
            } else if errorMessage == nil {
                errorMessage = error.message
            }
        } catch {
            if errorMessage == nil {
                errorMessage = error.userMessage
            }
        }
    }

    private func save() async {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        if let _ = await store.saveRating(
            fairId: fairId,
            projectId: projectId,
            rating: stars,
            comment: comment
        ) {
            savedNote = true
        } else {
            errorMessage = store.errorMessage
        }
    }
}

private struct PhotoViewer: View {
    let urls: [String]
    let index: Int
    let onClose: () -> Void

    @State private var page: Int
    @State private var scale: CGFloat = 1

    init(urls: [String], index: Int, onClose: @escaping () -> Void) {
        self.urls = urls
        self.index = index
        self.onClose = onClose
        _page = State(initialValue: index)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $page) {
                ForEach(Array(urls.enumerated()), id: \.offset) { offset, url in
                    CoverImage(url: URL(string: url))
                        .scaleEffect(scale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    scale = min(max(value.magnification, 1), 4)
                                }
                                .onEnded { _ in
                                    if scale < 1.05 { scale = 1 }
                                }
                        )
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
        .overlay(alignment: .top) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.black.opacity(0.45)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
            .zIndex(10)
        }
    }
}
