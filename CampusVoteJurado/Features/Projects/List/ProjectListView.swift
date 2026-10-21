import SwiftUI

struct ProjectListView: View {
    let fairId: String

    @Environment(\.locale) private var locale
    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairsStore
    @Environment(TabBarVisibility.self) private var tabBar
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ProjectsViewModel?
    @State private var projectRoute: ProjectRoute?
    @State private var showFilters = false
    @State private var statusFilter: StatusFilter = .all
    @State private var draftStatus: StatusFilter = .all

    private let naranja = Color(red: 0.85, green: 0.45, blue: 0.12)
    private let verde = Color(red: 0.13, green: 0.62, blue: 0.36)

    private var fairName: String {
        (fairsStore.activeFairs + fairsStore.closedFairs)
            .first { $0.fair.id == fairId }?
            .fair.name ?? L10n.tr("Proyectos", locale: locale)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if let viewModel {
                list(viewModel)
            } else {
                Spacer()
                ProgressView("Cargando proyectos...")
                Spacer()
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $projectRoute) { route in
            ProjectDetailView(fairId: fairId, projectId: route.id)
        }
        .task {
            if viewModel == nil {
                viewModel = ProjectsViewModel(fairId: fairId, store: store)
            }
            await viewModel?.load()
        }
        .onChange(of: showFilters) { _, open in
            tabBar.isHidden = open
        }
        .onDisappear {
            tabBar.isHidden = false
        }
        .overlay(alignment: .bottom) {
            if showFilters {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { showFilters = false }

                    ProjectListFilterSheet(
                        draftStatus: $draftStatus,
                        projects: store.projects,
                        naranja: naranja,
                        verde: verde,
                        onCancel: { showFilters = false },
                        onApply: {
                            statusFilter = draftStatus
                            showFilters = false
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.easeOut(duration: 0.25), value: showFilters)
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Proyectos")
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

                    Button {
                        draftStatus = statusFilter
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.onBrand)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filtros")
                }
            }
            .padding(.horizontal, 8)

            Rectangle()
                .fill(Color.onBrand.opacity(0.35))
                .frame(height: 0.5)
        }
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

    private func list(_ viewModel: ProjectsViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let projects = listed(viewModel.projects)

        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(fairName)
                    .font(.subheadline.weight(.semibold))

                Text(L10n.format("%d de %d", locale: locale, viewModel.ratedCount, viewModel.totalCount))
                    .font(.headline)
                Text("proyectos con reseña")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message)
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("Buscar por proyecto, stand o tecnología...", text: $viewModel.search)
                        .font(.subheadline)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !viewModel.search.isEmpty {
                        Button {
                            viewModel.search = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("Todas", selected: viewModel.categoryId == nil) {
                            viewModel.categoryId = nil
                        }
                        ForEach(viewModel.categories) { category in
                            chip(category.name, selected: viewModel.categoryId == category.id) {
                                viewModel.categoryId = category.id
                            }
                        }
                    }
                }

                if viewModel.isLoading && viewModel.projects.isEmpty {
                    ProgressView("Cargando proyectos...")
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else if projects.isEmpty {
                    Text("No se encontraron proyectos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(projects) { project in
                            Button {
                                projectRoute = ProjectRoute(id: project.id)
                            } label: {
                                ProjectCoverCard(project: project, naranja: naranja, verde: verde)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private func listed(_ projects: [ReviewProject]) -> [ReviewProject] {
        switch statusFilter {
        case .all:
            return projects
        case .pending:
            return projects.filter(\.sinResena)
        case .rated:
            return projects.filter { !$0.sinResena }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(L10n.tr(title, locale: locale))
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.onBrand : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(selected ? Color.brand : Color.cardBackground))
        }
        .buttonStyle(.plain)
    }
}
