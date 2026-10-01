import SwiftUI

struct ProjectListView: View {
    let fairId: String

    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairsStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ProjectsViewModel?

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
        .task {
            if viewModel == nil {
                viewModel = ProjectsViewModel(fairId: fairId, store: store)
            }
            await viewModel?.load()
        }
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
                    TextField("Buscar proyecto", text: $viewModel.search)
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
                } else if viewModel.projects.isEmpty {
                    Text("No se encontraron proyectos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.projects) { project in
                            NavigationLink {
                                ProjectDetailView(fairId: fairId, projectId: project.id)
                            } label: {
                                ProjectCoverCard(project: project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(18)
        }
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

private struct ProjectCoverCard: View {
    let project: ReviewProject

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(project.categoryName ?? "Sin categoría")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let rating = project.myRating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(star <= rating ? Color.brandGold : Color.appNeutral)
                            }
                        }
                    } else {
                        Text("Sin reseña")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brand)
                    }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
