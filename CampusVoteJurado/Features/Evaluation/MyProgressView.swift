import SwiftUI

/// Panel de avance del jurado en una feria.
/// El conteo sale de GET /fairs/my-progress/:fairId.
/// La lista de calificados sale de GET /fairs/my-evaluations.
struct MyProgressView: View {
    let fairId: String

    @State private var progress: JuryProgress?
    @State private var evaluations: [Evaluation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let api = APIClient.shared
    private let tealDark = Color(red: 0.03, green: 0.32, blue: 0.28)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

                if isLoading {
                    ProgressView("Cargando tu avance...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let progress {
                    header(progress)
                    statsGrid(progress)

                    if evaluations.isEmpty {
                        Text("Aún no has calificado proyectos en esta feria.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        evaluatedSection(evaluations)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Mi avance")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func header(_ progress: JuryProgress) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(tealDark.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(progress.progressPercentage ?? 0) / 100)
                    .stroke(tealDark, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(progress.progressPercentage ?? 0))%")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(tealDark)
                    Text("avance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            .padding(.top, 8)

            Text(progress.fairName ?? "Feria")
                .font(.title3).bold()
                .multilineTextAlignment(.center)

            if let declaration = progress.declaration, let date = declaration.signedAt {
                Label("Declaración firmada \(fechaLegible(date))", systemImage: "checkmark.seal.fill")
                    .font(.caption).bold()
                    .foregroundColor(.green)
            } else {
                Label("Declaración pendiente de firmar", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).bold()
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private func statsGrid(_ progress: JuryProgress) -> some View {
        HStack(spacing: 12) {
            statCard(title: "Total evaluables", value: progress.totalProjects, systemImage: "rectangle.stack.fill")
            statCard(title: "Calificados", value: progress.evaluatedProjects, systemImage: "checkmark.circle.fill")
            statCard(title: "Pendientes", value: progress.remaining, systemImage: "clock.fill")
        }
    }

    private func statCard(title: String, value: Int, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(tealDark)
            Text("\(value)")
                .font(.title2.bold().monospacedDigit())
                .foregroundColor(.primary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
    }

    private func evaluatedSection(_ evaluations: [Evaluation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CALIFICADOS")
                .font(.caption).bold()
                .foregroundColor(.secondary)

            ForEach(evaluations) { evaluation in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(evaluation.project?.name ?? "Proyecto")
                            .font(.subheadline).bold()
                            .lineLimit(1)
                        if let comment = evaluation.comment, !comment.isEmpty {
                            Text(comment)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    if let total = evaluation.totalScore {
                        Text(total.formatted(.number.precision(.fractionLength(0...1))))
                            .font(.headline.bold().monospacedDigit())
                            .foregroundColor(tealDark)
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            progress = try await api.send(Endpoint.myProgress(fairId: fairId), as: JuryProgress.self)
            evaluations = try await api.send(Endpoint.myEvaluations(fairId: fairId), as: [Evaluation].self)
        } catch {
            errorMessage = error.userMessage
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
