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
    @State private var status: StatusFilter = .pending
    @State private var route: ProjectRoute?
    @State private var showScanner = false
    @State private var scanError: String?
    @State private var showsCategories = false
    @State private var filterBottom: CGFloat = 0

    private var assignment: FairAssignment? { fairs.allFairs.first { $0.id == fairId } }

    private var access: ReviewAccess {
        store.access(fairId: fairId, fallback: assignment?.access ?? ReviewAccess())
    }

    private var canScan: Bool {
        access.phase == .live && access.canReview != false
    }

    private var listMatchesFair: Bool {
        store.fairId == fairId && store.scope == scope
    }

    private var listIsLoading: Bool {
        if store.errorMessage != nil && store.projects.isEmpty { return false }
        if !listMatchesFair { return true }
        return store.isLoading && store.projects.isEmpty
    }

    private var visible: [ReviewProject] {
        guard listMatchesFair else { return [] }
        return store.filtered(search: search, categoryId: categoryId).filter {
            switch status {
            case .all: return true
            case .pending: return $0.sinResena
            case .rated: return !$0.sinResena
            }
        }
    }

    private var categoryTitle: String {
        store.categories.first { $0.id == categoryId }?.name ?? "Todas"
    }

    private var progressLine: String {
        let total = store.summary.total
        let noun = total == 1 ? "proyecto" : "proyectos"
        return "\(store.summary.rated) reseñados de \(total) \(noun)"
    }

    var body: some View {
        VStack(spacing: 0) {
            OrganizationHeader(title: "Proyectos")
            backRow

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(assignment?.fair.name ?? L10n.tr("Feria", locale: locale))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    FairReviewNotice(access: access)
                    searchField
                    filters
                    listBody
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .coordinateSpace(name: "projectList")
                .overlay(alignment: .top) {
                    if showsCategories {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: filterBottom)
                                .allowsHitTesting(false)
                            Color.black.opacity(0.18)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture { closeCategories() }
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if showsCategories {
                        categoryMenu
                            .padding(.top, filterBottom + 6)
                            .padding(.trailing, 20)
                    }
                }
            }
            .refreshable { await reload() }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onPreferenceChange(FilterBottomKey.self) { filterBottom = $0 }
        .navigationDestination(item: $route) { destination in
            ProjectDetailView(fairId: fairId, projectId: destination.id)
        }
        .task(id: scope) {
            categoryId = nil
            await reload()
        }
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

    private var backRow: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(L10n.tr("Volver", locale: locale))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brand)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            if canScan {
                Button { showScanner = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "qrcode.viewfinder")
                        Text(L10n.tr("Escanear QR", locale: locale))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.brand, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(Color.appNeutral)
            TextField("Buscar proyecto o categoría", text: $search)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.appNeutral)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpiar búsqueda")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .premiumSurface(cornerRadius: 12)
    }

    private var filters: some View {
        HStack(alignment: .center, spacing: 16) {
            statusTab(.pending)
            statusTab(.rated)
            statusTab(.all)
            Spacer(minLength: 8)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsCategories.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(L10n.tr(categoryTitle, locale: locale))
                        .lineLimit(1)
                    Image(systemName: showsCategories ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brand)
            }
            .buttonStyle(.plain)
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FilterBottomKey.self,
                    value: proxy.frame(in: .named("projectList")).maxY
                )
            }
        )
        .zIndex(2)
    }

    private func statusTab(_ item: StatusFilter) -> some View {
        let selected = status == item
        return Button {
            status = item
            closeCategories()
        } label: {
            VStack(spacing: 8) {
                Text(L10n.tr(statusTitle(item), locale: locale))
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color.brand : .secondary)
                Rectangle()
                    .fill(selected ? Color.brand : Color.clear)
                    .frame(height: 2)
            }
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    private func statusTitle(_ item: StatusFilter) -> String {
        switch item {
        case .pending: return "Pendientes"
        case .rated: return "Reseñados"
        case .all: return "Todos"
        }
    }

    private var categoryMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            categoryRow(title: "Todas", selected: categoryId == nil) {
                categoryId = nil
            }
            ForEach(store.categories) { category in
                Divider()
                categoryRow(title: category.name, selected: categoryId == category.id) {
                    categoryId = category.id
                }
            }
        }
        .frame(minWidth: 220)
        .premiumSurface(raised: true)
    }

    private func categoryRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            closeCategories()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(selected ? Color.brand : .clear)
                    .frame(width: 16)
                Text(title)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color.brand : .primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 12)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var listBody: some View {
        if listIsLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if let message = store.errorMessage, store.projects.isEmpty {
            ScreenStateView(
                icon: "exclamationmark.triangle",
                title: "No pudimos cargar los proyectos",
                message: message,
                actionTitle: "Reintentar"
            ) {
                Task { await reload() }
            }
        } else {
            Text(progressLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if visible.isEmpty {
                ScreenStateView(
                    icon: search.isEmpty ? "tray" : "magnifyingglass",
                    title: search.isEmpty ? "Sin proyectos en esta vista" : "Sin resultados",
                    message: search.isEmpty
                        ? "Prueba otra categoría o el filtro Todos."
                        : "Prueba con otro nombre o categoría."
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(visible) { project in
                        Button { route = ProjectRoute(id: project.id) } label: {
                            ProjectCoverCard(project: project)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func closeCategories() {
        guard showsCategories else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showsCategories = false
        }
    }

    private func reload() async {
        await fairs.fetchMyAssignments()
        if assignment?.access.phase != .live { scope = .assigned }
        await store.load(fairId: fairId, scope: scope)
    }
}

private struct FilterBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

enum StatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case rated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .pending: return "Sin reseña"
        case .rated: return "Evaluados"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .pending: return "clock"
        case .rated: return "checkmark"
        }
    }

    func tint(brand: Color, naranja: Color, verde: Color) -> Color {
        switch self {
        case .all: return brand
        case .pending: return naranja
        case .rated: return verde
        }
    }
}
