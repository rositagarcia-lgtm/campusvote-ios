import SwiftUI

struct ProjectDetailView: View {
    let fairId: String
    let projectId: String

    @Environment(ProjectsStore.self) var store
    @Environment(FairsStore.self) var fairs
    @Environment(TabBarVisibility.self) var tabBar
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale
    @Environment(\.scenePhase) var scenePhase

    @State var detail: ProjectDetail?
    @State var isLoading = true
    @State var isSaving = false
    @State var ratingLoaded = false
    @State var detailLoadID = UUID()
    @State var errorMessage: String?
    @State var stars = 0
    @State var comment = ""
    @State var aspects: Set<String> = []
    @State var photoIndex: Int?
    @State var bannerPage = 0
    @State var saveAlert: SaveAlert?

    struct SaveAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    let api = APIClient.shared
    let aspectos = [
        "Prototipo funcional",
        "Buena explicación",
        "Viabilidad técnica",
    ]

    @State var loadedAccess: ReviewAccess?

    var reviewAccess: ReviewAccess {
        let fallback = loadedAccess ?? fairs.allFairs.first { $0.id == fairId }?.access ?? ReviewAccess()
        return store.access(fairId: fairId, fallback: fallback)
    }

    var commentCount: Int {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count
    }

    var canSave: Bool {
        reviewAccess.allowsReview && ratingLoaded && !isSaving
            && (1...5).contains(stars) && (10...1000).contains(commentCount)
    }

    var commentHint: String? {
        guard commentCount > 0, commentCount < 10 else { return nil }
        return L10n.format("Faltan %d caracteres para poder guardar.", locale: locale, 10 - commentCount)
    }

    var highlightsKey: String {
        "campusvote.jury.highlights.\(SessionArchive.load()?.id ?? "anonymous").\(projectId)"
    }

    var body: some View {
        VStack(spacing: 0) {
            ProjectDetailHeader(onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    FairReviewNotice(access: reviewAccess).padding(.horizontal, 16)
                    if let errorMessage {
                        ScreenStateView(icon: "exclamationmark.triangle", title: "No pudimos cargar el proyecto",
                                        message: errorMessage, actionTitle: "Reintentar") {
                            Task { await load() }
                        }
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

                            ProjectMembersCard(members: detail.members)
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
        .refreshable { await load() }
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshReviewAccess() } }
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

    @ViewBuilder
    var reviewCard: some View {
        if reviewAccess.allowsReview && ratingLoaded {
            ProjectReviewCard(
                stars: $stars,
                comment: $comment,
                aspects: $aspects,
                aspectOptions: aspectos,
                highlightsKey: highlightsKey,
                canSave: canSave,
                isSaving: isSaving,
                commentHint: commentHint
            ) {
                Task { await save() }
            }
        }
    }

}
