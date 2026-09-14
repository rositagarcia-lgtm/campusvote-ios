import SwiftUI

@main
struct CampusVoteJuradoApp: App {

    @State private var session: SessionStore
    @State private var fairsStore: FairsStore

    init() {
        let api = APIClient()

        _session = State(
            initialValue: SessionStore(api: api)
        )

        _fairsStore = State(
            initialValue: FairsStore(api: api)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(fairsStore)
        }
    }
}
