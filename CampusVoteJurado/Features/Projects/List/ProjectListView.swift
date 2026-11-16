import SwiftUI

struct ProjectListView: View {
    let fairId: String
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairs
    @Environment(SessionStore.self) private var session
    @State private var search = ""
    @State private var categoryId: String?
    @State private var route: ProjectRoute?
    @State private var showScanner = false
    @State private var scanError: String?

    private var assignment: FairAssignment? { fairs.allFairs.first { $0.id == fairId } }
    private var access: ReviewAccess {
        store.access(fairId: fairId, fallback: assignment?.access ?? ReviewAccess())
    }
    private var visible: [ReviewProject] {
        guard store.fairId == fairId else { return [] }
        return store.filtered(search: search, categoryId: categoryId)
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
                    if let name = assignment?.fair.name {
                        ProseText(text: name, font: .title2, weight: .bold)
                    } else {
                        Text(L10n.tr("Feria", locale: locale)).font(.title2.bold())
                    }
                    FairReviewNotice(access: access)
                    TextField("Buscar proyecto o categoría", text: $search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(AppSpacing.standard)
                        .frame(minHeight: 44)
                        .premiumSurface()
                    categoryChips
                    if let message = store.errorMessage {
                        ScreenStateView(icon: "exclamationmark.triangle", title: "No pudimos cargar los proyectos",
                                        message: message, actionTitle: "Reintentar") {
                            Task { await reload() }
                        }
                    } else if store.isLoading && visible.isEmpty {
                        ProgressView("Cargando proyectos...").frame(maxWidth: .infinity, minHeight: 120)
                    } else if visible.isEmpty {
                        ScreenStateView(icon: "tray", title: "Sin resultados",
                                        message: "No se encontraron proyectos.")
                    } else {
                        Text(L10n.format("%d de %d", locale: locale, visible.filter { !$0.sinResena }.count, visible.count))
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
        .task { await reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reload() } }
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

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: L10n.tr("Todas", locale: locale), selected: categoryId == nil) {
                    categoryId = nil
                }
                ForEach(store.categories) { category in
                    categoryChip(title: category.name, selected: categoryId == category.id) {
                        categoryId = category.id
                    }
                }
            }
        }
    }

    private func categoryChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.onBrand : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .background(Capsule().fill(selected ? Color.brand : Color.cardBackground))
        }
        .buttonStyle(.plain)
    }

    private func reload() async {
        await fairs.fetchMyAssignments()
        async let brand: Void = session.refreshBrand()
        async let list: Void = store.load(fairId: fairId, scope: .all)
        _ = await (brand, list)
    }
}
