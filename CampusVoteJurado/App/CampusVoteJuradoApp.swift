import SwiftUI

@main
struct CampusVoteJuradoApp: App {

    @State private var session: SessionStore
    @State private var fairsStore: FairsStore
    @State private var projectsStore: ProjectsStore
    @State private var catalogStore: ProjectsCatalogStore
    @State private var tabBar = TabBarVisibility()
    @AppStorage("campusvote.preferences.appearance") private var appearance = "system"

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
        _catalogStore = State(initialValue: ProjectsCatalogStore(api: api))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(fairsStore)
                .environment(projectsStore)
                .environment(catalogStore)
                .environment(tabBar)
                .modifier(PreferredTextSize())
                .preferredColorScheme(preferredScheme)
        }
    }
}

private struct PreferredTextSize: ViewModifier {
    @Environment(\.dynamicTypeSize) private var systemSize
    @AppStorage("campusvote.preferences.textSize") private var textSize = "normal"

    func body(content: Content) -> some View {
        let preferred: DynamicTypeSize
        switch textSize {
        case "small": preferred = .medium
        case "large": preferred = .xxxLarge
        default: preferred = systemSize
        }
        return content.dynamicTypeSize(preferred)
    }
}
