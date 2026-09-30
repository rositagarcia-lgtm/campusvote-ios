import SwiftUI

/// Rúbrica de un proyecto: cada criterio se marca o se deja sin marcar.
/// El borrador se puede repetir. Al enviar, la hoja queda solo lectura.
struct EvaluateView: View {
    let fairId: String
    let project: Project
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var criteria: [Criterion] = []
    @State private var checked: [String: Bool] = [:]
    @State private var isSubmitted = false
    @State private var score: Double?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedMessage: String?

    private let api = APIClient.shared

    var body: some View {
        VStack(spacing: 0) {
            encabezado

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    identidad

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                    if let savedMessage {
                        Label(savedMessage, systemImage: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(Color.brand)
                    }

                    if isLoading {
                        ProgressView("Cargando rúbrica...")
                            .frame(maxWidth: .infinity, minHeight: 160)
                    } else if criteria.isEmpty {
                        vacio
                    } else {
                        Text("Marca los criterios que cumple. Todos valen igual.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(criteria) { criterion in
                            criterio(criterion)
                        }

                        if isSubmitted {
                            Text("Enviada. Tu calificación es \(scoreText) / 20. No hay aprobado ni reprobado, y este número no elige al ganador.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ProjectVotePanel(fairId: fairId, projectId: project.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            if !isSubmitted && !criteria.isEmpty {
                barra
            }
        }
        .task { await load() }
    }

    private var encabezado: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Rúbrica")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.onBrand)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Volver")
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.onBrand.opacity(0.35))
                .frame(height: 0.5)
        }
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

    private var identidad: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name)
                .font(.headline)
            HStack(spacing: 8) {
                if let category = project.category, !category.isEmpty {
                    Text(category)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.brand.opacity(0.12)))
                }
                if let stand = project.tableNumber, !stand.isEmpty {
                    Label("Stand \(stand)", systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }

    private func criterio(_ criterion: Criterion) -> some View {
        let marcado = checked[criterion.id] == true
        return Button {
            guard !isSubmitted else { return }
            checked[criterion.id] = !marcado
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: marcado ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(marcado ? Color.brand : Color.appNeutral)

                VStack(alignment: .leading, spacing: 4) {
                    Text(criterion.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if let description = criterion.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isSubmitted)
    }

    private var vacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 36))
                .foregroundStyle(Color.brand)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.brand.opacity(0.12)))
            Text("Sin criterios activos")
                .font(.headline)
            Text("Este proyecto no tiene criterios para calificar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private var barra: some View {
        HStack(spacing: 10) {
            Button("Guardar borrador") { Task { await save(finalize: false) } }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brand, lineWidth: 1)
                )

            Button("Enviar rúbrica") { Task { await save(finalize: true) } }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.onBrand)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.brand)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isSaving)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.appBackground)
    }

    private var scoreText: String {
        let value = score ?? draftScore
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }

    /// Solo se muestra después de enviar. Marcados / activos × 20.
    private var draftScore: Double {
        guard !criteria.isEmpty else { return 0 }
        let marked = criteria.filter { checked[$0.id] == true }.count
        return Double(marked) / Double(criteria.count) * 20
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
