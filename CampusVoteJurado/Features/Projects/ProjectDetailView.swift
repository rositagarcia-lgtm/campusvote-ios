import SwiftUI

/// Pantalla 05 · Detalle del proyecto antes de evaluarlo.
struct ProjectDetailView: View {
    let route: ProjectRoute
    @Environment(ProjectsStore.self) private var projects
    @Environment(FairsStore.self) private var fairs
    @Environment(EvaluationStore.self) private var evaluation
    @State private var detail: ProjectDetail?

    private var project: ProjectCard { route.project }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CoverImage(url: detail?.coverUrl ?? project.coverUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(project.name)
                    .font(.title2.bold())

                HStack(spacing: 12) {
                    if let stand = detail?.stand ?? project.stand {
                        Label(stand.code, systemImage: "mappin.and.ellipse")
                    }
                    if let category = detail?.category ?? project.category {
                        Label(category.name, systemImage: "tag")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let description = detail?.description ?? project.description {
                    Text(description)
                }

                if let link = detail?.projectUrl {
                    Link("Abrir el enlace del proyecto", destination: link)
                }

                if let members = detail?.members, !members.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Integrantes")
                            .font(.headline)
                        ForEach(members) { member in
                            HStack {
                                Text(member.displayName)
                                Spacer()
                                Text(member.roleLabel)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                evaluateAction
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Proyecto")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            detail = await projects.detail(fairId: route.fair.id, projectId: project.id)
        }
    }

    /// Solo se puede evaluar con la feria abierta e iniciada y la declaración firmada.
    @ViewBuilder
    private var evaluateAction: some View {
        if !route.fair.isOpen {
            Text("La feria está cerrada: solo puedes ver el proyecto.")
                .foregroundStyle(.secondary)
        } else if !route.fair.hasStarted {
            Text("La evaluación empieza cuando inicia la feria.")
                .foregroundStyle(.secondary)
        } else if fairs.signed[route.fair.id] != true {
            Text("Firma la declaración de imparcialidad para evaluar.")
                .foregroundStyle(.secondary)
        } else {
            NavigationLink(
                value: EvaluateRoute(fair: route.fair, projectId: project.id, projectName: project.name)
            ) {
                Text(evaluation.evaluation(for: project.id) == nil ? "Evaluar" : "Corregir mi evaluación")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
