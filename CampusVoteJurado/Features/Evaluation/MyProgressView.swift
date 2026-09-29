import SwiftUI

/// Avance del jurado en una feria.
/// El conteo sale de GET /fairs/my-progress/{fairId}.
/// El detalle por categoría sale de GET /fairs/{fairId}/my-rubrics.
struct MyProgressView: View {
    let fairId: String

    @State private var progress: JuryProgress?
    @State private var groups: [CategoryRubricSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var groupsError: String?

    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isLoading && progress == nil {
                    ProgressView("Cargando tu avance...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let progress {
                    resumen(progress)
                    categorias
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await load() }
        .task { await load() }
    }

    // MARK: - Resumen

    private func resumen(_ progress: JuryProgress) -> some View {
        let percent = porcentaje(progress)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(progress.fairName ?? "Feria")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                if let estado = etiquetaEstado(progress.fairStatus) {
                    Text(estado.titulo)
                        .font(.caption2.bold())
                        .foregroundStyle(estado.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(estado.color.opacity(0.12)))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(progress.completedProjects)")
                        .font(.title2.bold())
                        .foregroundStyle(Color.brand)
                    Text("de \(progress.totalProjects)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(percent.rounded()))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brand)
                }

                Text("Rúbricas enviadas")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.brand.opacity(0.15))
                        Capsule()
                            .fill(Color.brand)
                            .frame(width: geo.size.width * min(1, percent / 100))
                    }
                }
                .frame(height: 6)
            }

            HStack(spacing: 0) {
                cifra("Total", progress.totalProjects)
                Rectangle()
                    .fill(Color.appNeutral.opacity(0.25))
                    .frame(width: 0.5, height: 32)
                cifra("Enviados", progress.completedProjects)
                Rectangle()
                    .fill(Color.appNeutral.opacity(0.25))
                    .frame(width: 0.5, height: 32)
                cifra("Pendientes", progress.pendingProjects)
            }

            Divider()

            declaracion(progress)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }

    private func cifra(_ titulo: String, _ valor: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(valor)")
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(titulo)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func declaracion(_ progress: JuryProgress) -> some View {
        let firmada = progress.declarationSigned
        return HStack(spacing: 12) {
            Image(systemName: firmada ? "checkmark.seal" : "signature")
                .font(.body)
                .foregroundStyle(firmada ? Color.brand : Color.appNeutral)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((firmada ? Color.brand : Color.appNeutral).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(firmada ? "Declaración firmada" : "Falta firmar la declaración")
                    .font(.subheadline.weight(.semibold))
                if firmada, let raw = progress.declaration?.signedAt, !raw.isEmpty {
                    Text(fechaLegible(raw))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !firmada {
                    Text("Sin la firma no puedes evaluar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Categorías

    private var categorias: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Por categoría")
                .font(.subheadline.weight(.semibold))

            if let groupsError {
                ErrorBanner(message: groupsError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if groups.isEmpty {
                Text("Todavía no hay rúbricas en tus categorías.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(groups) { group in
                    categoria(group)
                }
            }
        }
    }

    private func categoria(_ group: CategoryRubricSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.categoryName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if let score = group.score {
                    Text("\(score.formatted(.number.precision(.fractionLength(0...1)))) / 20")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.brand)
                }
            }

            if group.criteriaCount > 0 {
                let fraction = min(1, Double(group.checkedCount) / Double(group.criteriaCount))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.brand.opacity(0.15))
                        Capsule()
                            .fill(Color.brand)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 6)
            }

            Text(detalle(group))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func detalle(_ group: CategoryRubricSummary) -> String {
        let enviadas = group.submittedCount == 1
            ? "1 enviada"
            : "\(group.submittedCount) enviadas"
        guard group.criteriaCount > 0 else { return enviadas }
        return "\(enviadas) · \(group.checkedCount) de \(group.criteriaCount) marcados"
    }

    // MARK: - Datos

    private func porcentaje(_ progress: JuryProgress) -> Double {
        if let value = progress.progressPercentage {
            return min(100, max(0, value))
        }
        guard progress.totalProjects > 0 else { return 0 }
        return Double(progress.completedProjects) / Double(progress.totalProjects) * 100
    }

    private func etiquetaEstado(_ raw: String?) -> (titulo: String, color: Color)? {
        guard let raw, !raw.isEmpty else { return nil }
        switch raw.uppercased() {
        case "OPEN":
            return ("Abierta", Color.brand)
        case "CLOSED":
            return ("Cerrada", Color.appNeutral)
        default:
            return (raw.capitalized, Color.appNeutral)
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        groupsError = nil
        defer { isLoading = false }

        do {
            progress = try await api.send(Endpoint.myProgress(fairId: fairId), as: JuryProgress.self)
        } catch {
            errorMessage = error.userMessage
        }

        do {
            groups = try await api.send(Endpoint.myRubrics(fairId: fairId), as: MyRubricsPayload.self).groups
        } catch {
            groupsError = error.userMessage
        }
    }

    private func fechaLegible(_ raw: String) -> String {
        let withMillis = ISO8601DateFormatter()
        withMillis.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let date = withMillis.date(from: raw) ?? plain.date(from: raw) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return raw
    }
}
