import SwiftUI

struct MyProjectsView: View {
    @Environment(\.locale) private var locale
    @Environment(ProjectsStore.self) private var store
    @Environment(FairsStore.self) private var fairs
    @Environment(TabBarVisibility.self) private var tabBar
    @State private var route: AssignedRoute?
    @State private var exploreFair: ExploreFair?
    @State private var showsFairMenu = false
    @State private var closedFairCardHeight: CGFloat = 88

    private var browsableFairs: [FairAssignment] {
        fairs.allFairs.filter { assignment in
            switch assignment.access.phase {
            case .preview, .live, .ended: return true
            default: return false
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OrganizationHeader(title: "Asignados")

            ZStack(alignment: .top) {
                AssignedProjectsListView { project in
                    guard let fairId = project.fairId else { return }
                    route = AssignedRoute(fairId: fairId, projectId: project.id)
                }
                .padding(.top, closedFairCardHeight)

                if showsFairMenu {
                    Color.black.opacity(0.28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { closeFairMenu() }
                }

                fairMenu
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onPreferenceChange(ExploreCardHeightKey.self) { closedFairCardHeight = $0 }
        .navigationDestination(item: $route) { destination in
            ProjectDetailView(fairId: destination.fairId, projectId: destination.projectId)
        }
        .navigationDestination(item: $exploreFair) { fair in
            ProjectListView(fairId: fair.fairId)
        }
        .task {
            await fairs.fetchMyAssignments()
            await store.loadAssigned()
        }
        .onAppear { tabBar.isHidden = false }
        .onDisappear { showsFairMenu = false }
    }

    private var fairMenu: some View {
        VStack(spacing: 0) {
            Button {
                guard !browsableFairs.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsFairMenu.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.brand.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr("Explorar feria", locale: locale))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(L10n.tr("Elige una feria", locale: locale))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: showsFairMenu ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ExploreCardHeightKey.self,
                        value: proxy.size.height + 20
                    )
                }
            )

            if showsFairMenu && !browsableFairs.isEmpty {
                Divider().padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(browsableFairs) { assignment in
                        Button {
                            exploreFair = ExploreFair(fairId: assignment.id)
                            closeFairMenu()
                        } label: {
                            HStack(spacing: 12) {
                                Text(assignment.fair.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if assignment.id != browsableFairs.last?.id {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
            }
        }
        .premiumSurface(raised: showsFairMenu)
        .zIndex(2)
    }

    private func closeFairMenu() {
        guard showsFairMenu else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showsFairMenu = false
        }
    }
}

private struct AssignedRoute: Hashable, Identifiable {
    let fairId: String
    let projectId: String
    var id: String { "\(fairId)/\(projectId)" }
}

private struct ExploreFair: Hashable {
    let fairId: String
}

private struct ExploreCardHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 88
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
