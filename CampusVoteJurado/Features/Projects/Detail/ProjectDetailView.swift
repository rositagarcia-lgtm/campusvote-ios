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
    @Environment(SessionStore.self) var session

    @State var detail: ProjectDetail?
    @State var isLoading = true
    @State var isSaving = false
    @State var ratingLoaded = false
    @State var detailLoadID = UUID()
    @State var errorMessage: String?
    @State var stars = 0
    @State var comment = ""
    @State var photoIndex: Int?
    @State var bannerPage = 0
    @State var saveAlert: SaveAlert?
    @State var showReview = false

    struct SaveAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    let api = APIClient.shared

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

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let errorMessage {
                        ScreenStateView(icon: "exclamationmark.triangle", title: "No pudimos cargar el proyecto",
                                        message: errorMessage, actionTitle: "Reintentar") {
                            Task { await load() }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }

                    if isLoading {
                        ProgressView("Cargando proyecto...")
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else if let detail {
                        ProjectDetailBody(
                            detail: detail,
                            fairName: fairs.allFairs.first { $0.id == fairId }?.fair.name,
                            photos: gallery(detail),
                            page: $bannerPage,
                            access: reviewAccess,
                            onSelectPhoto: { photoIndex = $0 }
                        )
                    }
                }
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
        .refreshable {
            async let brand: Void = session.refreshBrand()
            async let detail: Void = load()
            _ = await (brand, detail)
        }
        .task { await load() }
        .onChange(of: photoIndex) { _, index in
            tabBar.isHidden = index != nil || showReview
        }
        .onChange(of: showReview) { _, open in
            tabBar.isHidden = open || photoIndex != nil
        }
        .onDisappear {
            tabBar.isHidden = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshReviewAccess() } }
        }
        .overlay {
            if showReview, let detail, reviewAccess.allowsReview && ratingLoaded {
                ProjectReviewSheet(
                    name: detail.name,
                    summary: detail.description,
                    imageURL: gallery(detail).first,
                    stars: $stars,
                    comment: $comment,
                    canSave: canSave,
                    isSaving: isSaving,
                    commentHint: commentHint,
                    errorMessage: errorMessage,
                    onSave: { Task { await save() } },
                    onClose: {
                        showReview = false
                        tabBar.isHidden = false
                    }
                )
                .ignoresSafeArea(edges: .bottom)
            }
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

    private var topBar: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Volver")

            Spacer(minLength: 0)

            if showsRateButton {
                Button {
                    tabBar.isHidden = true
                    showReview = true
                } label: {
                    Image(systemName: "star.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Calificar")
            }
        }
        .padding(.horizontal, 8)
        .background(Color.cardBackground)
    }

    var showsRateButton: Bool {
        reviewAccess.allowsReview && ratingLoaded && detail != nil && !isLoading && photoIndex == nil
    }

}
