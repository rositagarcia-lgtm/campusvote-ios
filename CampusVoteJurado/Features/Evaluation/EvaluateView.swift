import SwiftUI

/// Rúbrica de un proyecto: cada criterio se marca o se deja sin marcar.
/// El borrador se puede repetir. Al enviar, la hoja queda solo lectura.
struct EvaluateView: View {
    let fairId: String
    let project: Project
    let onSaved: () -> Void

    @State private var criteria: [Criterion] = []
    @State private var checked: [String: Bool] = [:]
    @State private var isSubmitted = false
    @State private var score: Double?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedMessage: String?

    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                        .font(.title2).bold()
                    HStack(spacing: 8) {
                        if let stand = project.tableNumber {
                            Label(stand, systemImage: "shippingbox.fill")
                                .font(.caption).bold()
                        }
                        if let category = project.category {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.brand.opacity(0.12))
                                .foregroundStyle(Color.brand)
                                .cornerRadius(6)
                        }
                    }
                    .foregroundStyle(.secondary)

                    NavigationLink {
                        ProjectDetailView(fairId: fairId, projectId: project.id)
                    } label: {
                        Label("Ver detalle del proyecto", systemImage: "doc.text.magnifyingglass")
                            .font(.caption).bold()
                    }

                    ProjectVotePanel(fairId: fairId, projectId: project.id)
                }

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }
                if let savedMessage {
                    Label(savedMessage, systemImage: "checkmark.seal.fill")
                        .font(.subheadline).bold()
                        .foregroundStyle(.green)
                }

                if isLoading {
                    ProgressView("Cargando rúbrica...")
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else if criteria.isEmpty {
                    Text("Este proyecto no tiene criterios activos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Marca los criterios que cumple. Todos valen igual.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(criteria) { criterion in
                        Toggle(isOn: binding(for: criterion.id)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(criterion.position). \(criterion.name)")
                                    .font(.subheadline.bold())
                                if let description = criterion.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .toggleStyle(.switch)
                        .disabled(isSubmitted)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }

                    if isSubmitted {
                        Text("Enviada. Puntaje \(scoreText). No hay aprobado ni reprobado, y este número no elige al ganador.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Rúbrica")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !isSubmitted && !criteria.isEmpty {
                actionBar
            }
        }
        .task { await load() }
    }

    private var scoreText: String {
        let value = score ?? draftScore
        return value.formatted(.number.precision(.fractionLength(0...2)))
    }

    /// Solo se muestra después de enviar. Marcados / activos × 20.
    private var draftScore: Double {
        guard !criteria.isEmpty else { return 0 }
        let marked = criteria.filter { checked[$0.id] == true }.count
        return Double(marked) / Double(criteria.count) * 20
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button("Guardar borrador") { Task { await save(finalize: false) } }
                .buttonStyle(.bordered)
            Button("Enviar rúbrica") { Task { await save(finalize: true) } }
                .buttonStyle(.borderedProminent)
        }
        .disabled(isSaving)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { checked[id] ?? false },
            set: { checked[id] = $0 }
        )
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let detail = try await api.send(
                .projectDetail(fairId: fairId, projectId: project.id),
                as: ProjectDetail.self
            )
            criteria = detail.activeCriteria
            let saved = try? await api.send(
                .projectRubric(fairId: fairId, projectId: project.id),
                as: SavedRubric.self
            )
            for criterion in criteria {
                checked[criterion.id] = saved?.isChecked(criterion.id) ?? false
            }
            isSubmitted = saved?.isSubmitted ?? false
            score = saved?.score
        } catch {
            errorMessage = error.userMessage
        }
    }

    @MainActor
    private func save(finalize: Bool) async {
        isSaving = true
        errorMessage = nil
        savedMessage = nil
        defer { isSaving = false }

        let body = RubricPutBody(
            responses: criteria.map {
                RubricResponseBody(criterionId: $0.id, checked: checked[$0.id] ?? false)
            },
            finalize: finalize
        )
        do {
            let saved = try await api.send(
                .saveRubric(fairId: fairId, projectId: project.id, body: body),
                as: SavedRubric.self
            )
            isSubmitted = saved.isSubmitted || finalize
            score = saved.score
            savedMessage = finalize ? "Rúbrica enviada. Ya no se puede editar." : "Borrador guardado."
            if finalize {
                onSaved()
            }
        } catch let error as APIError {
            if case .decoding = error {
                isSubmitted = finalize
                savedMessage = finalize ? "Rúbrica enviada. Ya no se puede editar." : "Borrador guardado."
                if finalize { onSaved() }
            } else {
                errorMessage = error.message
            }
        } catch {
            errorMessage = error.userMessage
        }
    }
}
