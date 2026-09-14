import SwiftUI

/// Pantalla 04 · Proyectos de la feria, con búsqueda y filtros por categoría y stand.
struct ProjectListView: View {
    let fair: Fair
    @Environment(FairsStore.self) private var fairs
    @Environment(ProjectsStore.self) private var projects
    @Environment(EvaluationStore.self) private var evaluation
    @State private var showDeclaration = false

    var body: some View {
        @Bindable var projects = projects

        List {
            if fairs.signed[fair.id] == false {
                Section {
                    Button("Firma la declaración para poder evaluar") {
                        showDeclaration = true
                    }
                }
            }

            if let message = projects.errorMessage {
                ErrorBanner(message: message)
            }

            ForEach(projects.projects) { project in
                NavigationLink(value: ProjectRoute(fair: fair, project: project)) {
                    ProjectRow(project: project, evaluated: evaluation.evaluation(for: project.id) != nil)
                }
            }
        }
        .overlay {
            if projects.projects.isEmpty && !projects.isLoading && projects.errorMessage == nil {
                ContentUnavailableView.search
            }
        }
        .searchable(text: $projects.search, prompt: "Buscar proyecto")
        .navigationTitle(fair.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Categoría", selection: $projects.categoryId) {
                        Text("Todas las categorías").tag(String?.none)
                        ForEach(projects.categories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                    Picker("Stand", selection: $projects.standId) {
                        Text("Todos los stands").tag(String?.none)
                        ForEach(projects.stands) { stand in
                            Text(stand.code).tag(Optional(stand.id))
                        }
                    }
                } label: {
                    Label("Filtrar", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: ProgressRoute(fair: fair)) {
                    Label("Mi avance", systemImage: "chart.bar")
                }
            }
        }
        .task {
            await projects.open(fairId: fair.id)
            await fairs.loadDeclaration(for: fair)
            await evaluation.load(fairId: fair.id)
        }
        .task(id: projects.filterKey) {
            await projects.load(fairId: fair.id)
        }
        .refreshable {
            await projects.load(fairId: fair.id)
            await evaluation.refreshProgress(fairId: fair.id)
        }
        .sheet(isPresented: $showDeclaration) {
            DeclarationView(fair: fair)
        }
    }
}

/// Fila de la lista: portada, nombre, stand, categoría y si ya lo evaluó.
private struct ProjectRow: View {
    let project: ProjectCard
    let evaluated: Bool

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: project.coverUrl)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    if let stand = project.stand {
                        Text(stand.code)
                            .font(.caption.monospaced())
                    }
                    if let category = project.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if evaluated {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Evaluado")
            }
        }
    }
}
