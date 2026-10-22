import SwiftUI

struct MyProjectsView: View {
    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairs
    @Environment(TabBarVisibility.self) private var tabBar
    @State private var route: AssignedRoute?

    var body: some View {
        VStack(spacing: 0) {
            OrganizationHeader(title: "Asignados")
            Menu {
                ForEach(fairs.allFairs.filter { $0.access.allowsBrowsing }) { assignment in
                    NavigationLink(assignment.fair.name) {
                        ProjectListView(fairId: assignment.id)
                    }
                }
            } label: {
                Label("Explorar feria", systemImage: "square.grid.2x2")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .disabled(!fairs.allFairs.contains { $0.access.allowsBrowsing })
            AssignedProjectsListView { project in
                guard let fairId = project.fairId else { return }
                route = AssignedRoute(fairId: fairId, projectId: project.id)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $route) { destination in
            ProjectDetailView(fairId: destination.fairId, projectId: destination.projectId)
        }
        .task {
            await fairs.fetchMyAssignments()
            await store.loadAssigned()
        }
        .onAppear { tabBar.isHidden = false }
    }
}

private struct AssignedRoute: Hashable, Identifiable {
    let fairId: String
    let projectId: String
    var id: String { "\(fairId)/\(projectId)" }
}
