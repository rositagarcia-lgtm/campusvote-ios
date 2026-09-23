import SwiftUI

@main
struct CampusVoteJuradoApp: App {

    @State private var session: SessionStore
    @State private var fairsStore: FairsStore
    @State private var projectsStore: ProjectsStore
    @State private var evaluationStore: EvaluationStore
    @State private var tabBar = TabBarVisibility()

    init() {
        let api = APIClient.shared

        _session = State(
            initialValue: SessionStore(api: api)
        )

        _fairsStore = State(
            initialValue: FairsStore(api: api)
        )

        _projectsStore = State(
            initialValue: ProjectsStore(api: api)
        )

        _evaluationStore = State(
            initialValue: EvaluationStore(api: api)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(fairsStore)
                .environment(projectsStore)
                .environment(evaluationStore)
                .environment(tabBar)
        }
    }
}
