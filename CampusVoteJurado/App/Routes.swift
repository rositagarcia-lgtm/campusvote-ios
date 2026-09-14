import Foundation

// Destinos de navegación. NavigationStack navega por valor: cada tipo de
// ruta abre una pantalla (se registran en FairListView).

struct ProjectRoute: Hashable {
    let fair: Fair
    let project: ProjectCard
}

struct EvaluateRoute: Hashable {
    let fair: Fair
    let projectId: String
    let projectName: String
}

struct ProgressRoute: Hashable {
    let fair: Fair
}
