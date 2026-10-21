import SwiftUI

/// Panel de proyectos del jurado. "Asignados" es para reseñar;
/// "Todos" muestra los aprobados de la feria en solo lectura.
struct MyProjectsView: View {
    @Environment(\.locale) private var locale
    @Environment(ProjectsStore.self) private var store
    @Environment(TabBarVisibility.self) private var tabBar

    @State private var mode: ProjectsMode = .assigned
    @State private var route: ProjectsRoute?
    @State private var showScanner = false
    @State private var scanError: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            modeSelector

            Group {
                switch mode {
                case .assigned:
                    AssignedProjectsListView { project in
                        openAssigned(project)
                    }
                case .all:
                    AllProjectsView { project in
                        openAll(project)
                    }
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $route) { route in
            switch route {
            case let .evaluate(fairId, projectId):
                ProjectDetailView(fairId: fairId, projectId: projectId)
            case let .info(fairId, projectId, fallback):
                PublicProjectView(fairId: fairId, projectId: projectId, fallback: fallback)
            }
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView { code in
                showScanner = false
                handleScan(code)
            }
        }
        .alert(
            "QR no reconocido",
            isPresented: Binding(
                get: { scanError != nil },
                set: { if !$0 { scanError = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) { scanError = nil }
        } message: {
            Text(L10n.tr(scanError ?? "", locale: locale))
        }
        .task {
            if !store.assignedLoaded {
                await store.loadAssigned()
            }
        }
        .onChange(of: route) { _, newValue in
            guard newValue == nil else { return }
            Task { await store.loadAssigned() }
        }
        .onAppear { tabBar.isHidden = false }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Proyectos")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)
                Text("Reseñas de la feria")
                    .font(.caption)
                    .foregroundStyle(Color.onBrand.opacity(0.8))
            }

            Spacer(minLength: 0)

            Button { showScanner = true } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Escanear QR")

            Button {
                Task {
                    if mode == .assigned {
                        await store.loadAssigned()
                    }
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Actualizar")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

    private var modeSelector: some View {
        HStack(spacing: 6) {
            ForEach(ProjectsMode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    Text(L10n.tr(item.title, locale: locale))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mode == item ? Color.onBrand : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(mode == item ? Color.brand : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private func openAssigned(_ project: ReviewProject) {
        guard let fairId = project.fairId else { return }
        route = .evaluate(fairId: fairId, projectId: project.id)
    }

    private func openAll(_ project: Project) {
        guard let fairId = project.fairId else {
            route = .info(fairId: nil, projectId: project.id, fallback: project)
            return
        }

        if store.isAssigned(projectId: project.id) {
            route = .evaluate(fairId: fairId, projectId: project.id)
        } else {
            route = .info(fairId: fairId, projectId: project.id, fallback: project)
        }
    }

    private func handleScan(_ code: String) {
        guard let payload = QRCodePayload.parse(code) else {
            scanError = "El código no corresponde a un proyecto de CampusVote."
            return
        }

        if let assigned = store.assignedProject(id: payload.projectId),
           let fairId = assigned.fairId {
            route = .evaluate(fairId: fairId, projectId: assigned.id)
            return
        }

        route = .info(fairId: payload.fairId, projectId: payload.projectId, fallback: nil)
    }
}

private enum ProjectsMode: String, CaseIterable, Identifiable {
    case assigned
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assigned: return "Asignados"
        case .all: return "Todos"
        }
    }
}

private enum ProjectsRoute: Hashable, Identifiable {
    case evaluate(fairId: String, projectId: String)
    case info(fairId: String?, projectId: String, fallback: Project?)

    var id: String {
        switch self {
        case let .evaluate(fairId, projectId):
            return "evaluate-\(fairId)-\(projectId)"
        case let .info(fairId, projectId, _):
            return "info-\(fairId ?? "none")-\(projectId)"
        }
    }
}
