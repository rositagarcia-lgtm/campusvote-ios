import SwiftUI

/// Punto de entrada. Crea los stores una sola vez y los comparte con todas las pantallas.
@main
struct CampusVoteJuradoApp: App {
    @State private var session = SessionStore(api: .shared)
    @State private var fairs = FairsStore(api: .shared)
    @State private var projects = ProjectsStore(api: .shared)
    @State private var evaluation = EvaluationStore(api: .shared)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(fairs)
                .environment(projects)
                .environment(evaluation)
        }
    }
}
