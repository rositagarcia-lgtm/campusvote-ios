import SwiftUI

struct ProjectDetailView: View {
    let fairId: String
    let projectId: String

    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairs
    @Environment(TabBarVisibility.self) private var tabBar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var detail: ProjectDetail?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var stars = 0
    @State private var comment = ""
    @State private var aspects: Set<String> = []
    @State private var photoIndex: Int?
    @State private var bannerPage = 0

    private let api = APIClient.shared
    private let aspectos = [
        "Prototipo funcional",
        "Buena explicación",
        "Viabilidad técnica",
    ]
    private let verdeAspecto = Color(red: 0.13, green: 0.62, blue: 0.36)

    private var fairIsClosed: Bool {
        fairs.closedFairs.contains { $0.fair.id == fairId }
    }

    private var commentCount: Int {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var canSave: Bool {
        !fairIsClosed && !isSaving && (1...5).contains(stars) && (10...300).contains(commentCount)
    }

    private var highlightsKey: String {
        "campusvote.jury.highlights.\(projectId)"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                            .padding(.horizontal, 16)
                    }

                    if isLoading {
                        ProgressView("Cargando proyecto...")
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else if let detail {
                        let fotos = gallery(detail)
                        if !fotos.isEmpty {
                            photoBanner(fotos)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            titleRow(detail)

                            if let description = detail.description,
                               !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                card {
                                    etiqueta("DESCRIPCIÓN")
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            if let video = detail.videoUrl, let url = URL(string: video) {
                                card {
                                    etiqueta("VIDEO")
                                    videoBlock(url: url, poster: heroURL(detail))
                                }
                            }

                            if let page = detail.projectUrl, let url = URL(string: page) {
                                card {
                                    etiqueta("ENLACE")
                                    enlaceRow(url)
                                }
                            }

                            reviewCard
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            loadHighlights()
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
                let urls = gallery(detail)
                if urls.indices.contains(photoIndex) {
                    PhotoViewer(
                        urls: urls,
                        index: photoIndex,
                        onClose: { self.photoIndex = nil }
                    )
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 2) {
            Button {
                dismiss()
            } label: {
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

    private func photoBanner(_ urls: [String]) -> some View {
        TabView(selection: $bannerPage) {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                CoverImage(url: URL(string: url))
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        photoIndex = index
                    }
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.caption2.weight(.semibold))
                Text("\(min(bannerPage + 1, urls.count))/\(urls.count)")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .padding(12)
            .allowsHitTesting(false)
        }
    }

    private func titleRow(_ detail: ProjectDetail) -> some View {
        HStack(alignment: .center, spacing: 10) {
            if let logo = detail.logoUrl {
                logoMark(logo)
            }

            Text(detail.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            if let category = detail.categoryName, !category.isEmpty {
                Text(category)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
        }
    }

    private func logoMark(_ urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 8).fill(Color.brand.opacity(0.12))
            }
        }
        .padding(4)
        .frame(width: 36, height: 36)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08)))
    }

    private func videoBlock(url: URL, poster: String?) -> some View {
        Button {
            openURL(url)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    CoverImage(url: poster.flatMap(URL.init(string:)))
                        .frame(maxWidth: .infinity)
                        .frame(height: 148)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Circle()
                        .fill(.white.opacity(0.94))
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.brand)
                                .offset(x: 1)
                        }
                }

                Text("Ver video del prototipo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func enlaceRow(_ url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.brand.opacity(0.12)))

                Text(enlaceVisible(url))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brand)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var reviewCard: some View {
        card {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tu reseña")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Evalúa el impacto y claridad del proyecto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if fairIsClosed {
                Text("Esta feria está cerrada.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        guard !fairIsClosed else { return }
                        stars = star
                    } label: {
                        Image(systemName: star <= stars ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundStyle(star <= stars ? Color.brandGold : Color.appNeutral)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .disabled(fairIsClosed)
                }

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.1f", Double(stars)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("/ 5")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                etiqueta("ASPECTOS DESTACADOS")
                ChipFlow(spacing: 8) {
                    ForEach(aspectos, id: \.self) { item in
                        aspectChip(item)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                etiqueta("COMENTARIOS ADICIONALES")
                commentBox
            }

            Button {
                Task { await save() }
            } label: {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(Color.onBrand)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.bold))
                            Text("Guardar reseña")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
                .foregroundStyle(Color.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.brand.opacity(canSave ? 1 : 0.4))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .padding(.top, 4)
        }
    }

    private func aspectChip(_ item: String) -> some View {
        let selected = aspects.contains(item)
        return Button {
            guard !fairIsClosed else { return }
            if selected {
                aspects.remove(item)
            } else {
                aspects.insert(item)
                insertAspect(item)
            }
            UserDefaults.standard.set(Array(aspects), forKey: highlightsKey)
        } label: {
            HStack(spacing: 4) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                    Text(item)
                } else {
                    Text("+ \(item)")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? verdeAspecto : Color.secondary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(selected ? verdeAspecto.opacity(0.12) : Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .disabled(fairIsClosed)
    }

    private func insertAspect(_ item: String) {
        let current = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.range(of: item, options: .caseInsensitive) != nil {
            return
        }
        let sentence = "\(item)."
        let next = current.isEmpty ? sentence : "\(current) \(sentence)"
        guard next.count <= 300 else { return }
        comment = next
    }

    private var commentBox: some View {
        ZStack(alignment: .topLeading) {
            if comment.isEmpty {
                Text("Escribe un comentario")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }

            TextEditor(text: $comment)
                .font(.subheadline)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 88)
                .disabled(fairIsClosed)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .bottomTrailing) {
            Text("\(min(commentCount, 300))/300")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.trailing, 10)
                .padding(.bottom, 8)
        }
        .onChange(of: comment) { _, newValue in
            if newValue.count > 300 {
                comment = String(newValue.prefix(300))
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func etiqueta(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func heroURL(_ detail: ProjectDetail) -> String? {
        if let cover = detail.coverUrl, !cover.isEmpty, cover != detail.logoUrl {
            return cover
        }
        return detail.imageUrls.first { $0 != detail.logoUrl && !$0.isEmpty }
    }

    private func gallery(_ detail: ProjectDetail) -> [String] {
        var urls: [String] = []
        if let hero = heroURL(detail) {
            urls.append(hero)
        }
        for url in detail.imageUrls where url != detail.logoUrl && !url.isEmpty && !urls.contains(url) {
            urls.append(url)
        }
        return urls
    }

    private func enlaceVisible(_ url: URL) -> String {
        guard let host = url.host, !host.isEmpty else {
            return url.absoluteString
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
        }
        var text = host + url.path
        if text.hasSuffix("/") {
            text.removeLast()
        }
        if let query = url.query, !query.isEmpty {
            text += "?\(query)"
        }
        return text
    }

    private func loadHighlights() {
        let saved = UserDefaults.standard.stringArray(forKey: highlightsKey) ?? []
        aspects = Set(saved.filter { aspectos.contains($0) })
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
            stars = min(max(loaded.rating ?? 0, 0), 5)
            comment = String((loaded.comment ?? "").prefix(300))
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

        if await store.saveRating(
            fairId: fairId,
            projectId: projectId,
            rating: stars,
            comment: comment
        ) == nil {
            errorMessage = store.errorMessage
        }
    }
}

private struct ChipFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
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
                    ZStack {
                        Color.black
                        AsyncImage(url: URL(string: url)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFit()
                            } else if phase.error != nil {
                                Image(systemName: "photo")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.7))
                            } else {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
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
                    }
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.black)
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
