import SwiftUI

struct ProjectDetailView: View {
    let fairId: String
    let projectId: String

    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairs
    @Environment(TabBarVisibility.self) private var tabBar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var detail: ProjectDetail?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var stars = 0
    @State private var comment = ""
    @State private var aspects: Set<String> = []
    @State private var photoIndex: Int?
    @State private var bannerPage = 0
    @State private var saveAlert: SaveAlert?

    private struct SaveAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private let api = APIClient.shared
    private let aspectos = [
        "Prototipo funcional",
        "Buena explicación",
        "Viabilidad técnica",
    ]

    private var fairIsClosed: Bool {
        fairs.closedFairs.contains { $0.fair.id == fairId }
    }

    private var commentCount: Int {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var canSave: Bool {
        !fairIsClosed && !isSaving && (1...5).contains(stars) && (10...1000).contains(commentCount)
    }

    private var commentHint: String? {
        guard commentCount > 0, commentCount < 10 else { return nil }
        return L10n.format("Faltan %d caracteres para poder guardar.", locale: locale, 10 - commentCount)
    }

    private var highlightsKey: String {
        "campusvote.jury.highlights.\(projectId)"
    }

    var body: some View {
        VStack(spacing: 0) {
            ProjectDetailHeader(onBack: { dismiss() })

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
                            ProjectGalleryBanner(urls: fotos, page: $bannerPage) { index in
                                photoIndex = index
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            ProjectIdentityRow(detail: detail)

                            if let description = detail.description,
                               !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                ProjectDetailCard {
                                    ProjectDetailLabel(title: "DESCRIPCIÓN")
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            if let video = detail.videoUrl, let url = URL(string: video) {
                                ProjectDetailCard {
                                    ProjectDetailLabel(title: "VIDEO")
                                    ProjectVideoBlock(url: url, poster: heroURL(detail))
                                }
                            }

                            if let page = detail.projectUrl, let url = URL(string: page) {
                                ProjectDetailCard {
                                    ProjectDetailLabel(title: "ENLACE")
                                    ProjectLinkRow(url: url)
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
        .alert(item: $saveAlert) { alert in
            Alert(
                title: Text(L10n.tr(alert.title, locale: locale)),
                message: Text(L10n.tr(alert.message, locale: locale)),
                dismissButton: .default(Text("Aceptar"))
            )
        }
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

    private var reviewCard: some View {
        ProjectReviewCard(
            stars: $stars,
            comment: $comment,
            aspects: $aspects,
            aspectOptions: aspectos,
            highlightsKey: highlightsKey,
            fairIsClosed: fairIsClosed,
            canSave: canSave,
            isSaving: isSaving,
            commentHint: commentHint
        ) {
            Task { await save() }
        }
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
