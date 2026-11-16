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
            if detail == nil {
                ProjectDetailHeader(onBack: { dismiss() })
            }

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
                            onSelectPhoto: { photoIndex = $0 },
                            onBack: { dismiss() }
                        )
                    }
                }
                .padding(.bottom, showsRateButton ? 88 : 20)
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
            tabBar.isHidden = index != nil
        }
        .onDisappear {
            tabBar.isHidden = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshReviewAccess() } }
        }
        .overlay(alignment: .bottomTrailing) {
            if showsRateButton {
                Button { showReview = true } label: {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(Color.onBrand)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.brand))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .accessibilityLabel("Calificar")
            }
        }
        .sheet(isPresented: $showReview) {
            if let detail, reviewAccess.allowsReview && ratingLoaded {
                ProjectReviewSheet(
                    name: detail.name,
                    summary: detail.description,
                    imageURL: gallery(detail).first,
                    stars: $stars,
                    comment: $comment,
                    canSave: canSave,
                    isSaving: isSaving,
                    commentHint: commentHint,
                    errorMessage: errorMessage
                ) {
                    Task { await save() }
                }
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

    var showsRateButton: Bool {
        reviewAccess.allowsReview && ratingLoaded && detail != nil && !isLoading && photoIndex == nil
    }

}
