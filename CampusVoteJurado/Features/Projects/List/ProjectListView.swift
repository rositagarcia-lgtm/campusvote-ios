import SwiftUI

struct ProjectListView: View {
    let fairId: String
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairs
    @State private var search = ""
    @State private var categoryId: String?
    @State private var scope: ReviewScope = .assigned
    @State private var status: StatusFilter = .all
    @State private var route: ProjectRoute?
    @State private var showScanner = false
    @State private var scanError: String?

    private var assignment: FairAssignment? { fairs.allFairs.first { $0.id == fairId } }
    private var access: ReviewAccess {
        store.access(fairId: fairId, fallback: assignment?.access ?? ReviewAccess())
    }
    private var visible: [ReviewProject] {
        guard store.fairId == fairId, store.scope == scope else { return [] }
        return store.filtered(search: search, categoryId: categoryId).filter {
            switch status {
            case .all: return true
            case .pending: return $0.sinResena
            case .rated: return !$0.sinResena
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OrganizationHeader(title: "Proyectos")
            HStack {
                Button { dismiss() } label: {
                    Label("Volver", systemImage: "chevron.left").frame(minHeight: 44)
                }
                Spacer()
                if access.allowsReview {
                    Button { showScanner = true } label: {
                        Label("Escanear QR", systemImage: "qrcode.viewfinder").frame(minHeight: 44)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text(assignment?.fair.name ?? L10n.tr("Feria", locale: locale)).font(.title2.bold())
                    FairReviewNotice(access: access)
                    if access.phase == .live {
                        Picker("Alcance de proyectos", selection: $scope) {
                            ForEach(ReviewScope.allCases) { item in
                                Text(L10n.tr(item.title, locale: locale)).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    TextField("Buscar proyecto o categoría", text: $search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(AppSpacing.standard)
                        .frame(minHeight: 44)
                        .premiumSurface()
                    Menu {
                        Button("Todas") { categoryId = nil }
                        ForEach(store.categories) { category in
                            Button(category.name) { categoryId = category.id }
                        }
                    } label: {
                        Label(store.categories.first { $0.id == categoryId }?.name
                              ?? L10n.tr("Todas", locale: locale), systemImage: "line.3.horizontal.decrease")
                            .frame(minHeight: 44)
                    }
                    Picker("Reseñas", selection: $status) {
                        Text("Todos").tag(StatusFilter.all)
                        Text("Pendientes").tag(StatusFilter.pending)
                        Text("Reseñados").tag(StatusFilter.rated)
                    }
                    .pickerStyle(.menu)
                    if let message = store.errorMessage {
                        ScreenStateView(icon: "exclamationmark.triangle", title: "No pudimos cargar los proyectos",
                                        message: message, actionTitle: "Reintentar") {
                            Task { await reload() }
                        }
                    } else if store.isLoading {
                        ProgressView("Cargando proyectos...").frame(maxWidth: .infinity, minHeight: 120)
                    } else if visible.isEmpty {
                        ScreenStateView(icon: "tray", title: "Sin resultados",
                                        message: "No se encontraron proyectos.")
                    } else {
                        Text(L10n.format("%d de %d", locale: locale, store.summary.rated, store.summary.total))
                            .font(.headline)
                        LazyVStack(spacing: AppSpacing.section) {
                            ForEach(visible) { project in
                                Button { route = ProjectRoute(id: project.id) } label: {
                                    ProjectCoverCard(project: project, naranja: .appWarning, verde: .appSuccess)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(AppSpacing.screen)
            }
            .refreshable { await reload() }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $route) { destination in
            ProjectDetailView(fairId: fairId, projectId: destination.id)
        }
        .task(id: scope) { categoryId = nil; await reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reload() } }
        }
        .onChange(of: access.phase) { _, phase in
            if phase != .live { scope = .assigned }
        }
        .onChange(of: store.scope) { _, actual in
            if store.fairId == fairId { scope = actual }
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView { raw in
                showScanner = false
                guard let payload = QRCodePayload.parse(raw) else {
                    scanError = "El código no corresponde a un proyecto de CampusVote."
                    return
                }
                guard payload.fairId == nil || payload.fairId == fairId else {
                    scanError = "El proyecto pertenece a otra feria."
                    return
                }
                route = ProjectRoute(id: payload.projectId)
            }
        }
        .alert("QR no reconocido", isPresented: Binding(get: { scanError != nil }, set: { if !$0 { scanError = nil } })) {
            Button("Aceptar", role: .cancel) { scanError = nil }
        } message: { Text(L10n.tr(scanError ?? "", locale: locale)) }
    }

    private func reload() async {
        await fairs.fetchMyAssignments()
        if assignment?.access.phase != .live { scope = .assigned }
        await store.load(fairId: fairId, scope: scope)
    }
}
