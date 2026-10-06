import SwiftUI

struct ProjectListView: View {
    let fairId: String

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
            .fair.name ?? "Proyectos"
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

                    filterSheet
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

                Text("\(viewModel.ratedCount) de \(viewModel.totalCount)")
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

    private var filterSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.primary.opacity(0.16))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)

            HStack(alignment: .center, spacing: 8) {
                Text("Filtros")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Button {
                    draftStatus = .all
                } label: {
                    Text("Restablecer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    showFilters = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar")
            }

            HStack {
                Text("ESTADO DE EVALUACIÓN")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text("Selecciona uno")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 10) {
                ForEach(StatusFilter.allCases) { item in
                    statusCard(item)
                }
            }

            HStack(spacing: 10) {
                Button {
                    showFilters = false
                } label: {
                    Text("Cancelar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    statusFilter = draftStatus
                    showFilters = false
                } label: {
                    HStack(spacing: 8) {
                        Text("Aplicar filtros")
                            .font(.subheadline.weight(.semibold))
                        Text("1")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.brand)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.onBrand))
                    }
                    .foregroundStyle(Color.onBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground.ignoresSafeArea(edges: .bottom))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
            )
        )
    }

    private func statusCard(_ item: StatusFilter) -> some View {
        let selected = draftStatus == item
        let tint = item.tint(brand: Color.brand, naranja: naranja, verde: verde)
        let total = count(item, in: store.projects)

        return Button {
            draftStatus = item
        } label: {
            VStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(itemsLabel(total))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? Color.brand.opacity(0.08) : Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.brand : Color.primary.opacity(0.1), lineWidth: selected ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.brand)
                        .background(Circle().fill(Color.cardBackground))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
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

    private func count(_ item: StatusFilter, in projects: [ReviewProject]) -> Int {
        switch item {
        case .all:
            return projects.count
        case .pending:
            return projects.filter(\.sinResena).count
        case .rated:
            return projects.filter { !$0.sinResena }.count
        }
    }

    private func itemsLabel(_ total: Int) -> String {
        total == 1 ? "1 item" : "\(total) items"
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.onBrand : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? Color.brand : Color.cardBackground)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ProjectRoute: Hashable {
    let id: String
}

private enum StatusFilter: String, CaseIterable, Identifiable {
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

private struct ProjectCoverCard: View {
    let project: ReviewProject
    let naranja: Color
    let verde: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                .frame(maxWidth: .infinity)
                .frame(height: 188)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Text(project.sinResena ? "Sin reseña" : "Evaluado")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(project.sinResena ? naranja : verde)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill((project.sinResena ? naranja : verde).opacity(0.14))
                        )
                }

                HStack(spacing: 6) {
                    if let category = project.categoryName, !category.isEmpty {
                        Text(category)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.primary.opacity(0.06)))
                    }
                    if let stand = project.standCode, !stand.isEmpty {
                        Text(stand)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.primary.opacity(0.06)))
                    }
                }

                if let team = project.teamName, !team.isEmpty {
                    Text(team)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(project.sinResena ? "Evaluación requerida" : "Reseña enviada")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(project.sinResena ? "Evaluar >" : "Ver >")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
