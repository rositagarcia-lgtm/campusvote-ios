import SwiftUI

/// Pantalla 07 · Mi avance: cuántos proyectos lleva y sus evaluaciones.
/// Se llama MyProgressView porque ProgressView ya es un componente de SwiftUI.
struct MyProgressView: View {
    let fair: Fair
    @Environment(EvaluationStore.self) private var evaluation

    var body: some View {
        List {
            if let progress = evaluation.progress {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(progress.evaluatedProjects) de \(progress.totalProjects) proyectos evaluados")
                            .font(.headline)
                        ProgressView(value: progress.progressPercentage, total: 100)
                        Text(progress.remaining == 0 ? "Terminaste. ¡Gracias!" : "Te faltan \(progress.remaining).")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Mis evaluaciones") {
                    ForEach(progress.evaluations) { item in
                        HStack {
                            Text(item.project?.name ?? "Proyecto")
                            Spacer()
                            Text(item.totalScore, format: .number)
                                .monospacedDigit()
                        }
                    }
                }
            } else if let message = evaluation.errorMessage {
                ErrorBanner(message: message)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Mi avance")
        .task { await evaluation.refreshProgress(fairId: fair.id) }
        .refreshable { await evaluation.refreshProgress(fairId: fair.id) }
    }
}
