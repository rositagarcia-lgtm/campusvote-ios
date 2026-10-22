import SwiftUI

@main
struct CampusVoteJuradoApp: App {

    @State private var session: SessionStore
    @State private var fairsStore: FairsStore
    @State private var projectsStore: ProjectsStore
    @State private var tabBar = TabBarVisibility()
    @AppStorage("campusvote.preferences.appearance") private var appearance = "system"
    @AppStorage("campusvote.preferences.language") private var language = "es"

    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    init() {
        let api = APIClient.shared

        _session = State(initialValue: SessionStore(api: api))
        _fairsStore = State(initialValue: FairsStore(api: api))
        _projectsStore = State(initialValue: ProjectsStore(api: api))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(fairsStore)
                .environment(projectsStore)
                .environment(tabBar)
                .environment(\.locale, Locale(identifier: language == "en" ? "en" : "es"))
                .modifier(PreferredTextSize())
                .preferredColorScheme(preferredScheme)
                .onChange(of: session.phase) { _, phase in
                    guard phase == .signedOut else { return }
                    fairsStore.reset()
                    projectsStore.reset()
                    tabBar.isHidden = false
                }
        }
    }
}

private struct PreferredTextSize: ViewModifier {
    @Environment(\.dynamicTypeSize) private var systemSize
    @AppStorage("campusvote.preferences.textSize") private var textSize = "normal"

    func body(content: Content) -> some View {
        let preferred: DynamicTypeSize
        switch textSize {
        case "small": preferred = max(systemSize, .medium)
        case "large": preferred = max(systemSize, .xxxLarge)
        default: preferred = systemSize
        }
        return content.dynamicTypeSize(preferred)
    }
}
