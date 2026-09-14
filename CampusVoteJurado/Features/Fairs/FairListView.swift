import SwiftUI

struct FairListView: View {
    @Environment(FairsStore.self) private var fairsStore

    @State private var path: [FairRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Sede y Estado
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.secondary)
                        Text("Tecsup · Trujillo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()

                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("En vivo")
                                .font(.caption).bold()
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    // Rol Activo Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title)
                                .foregroundColor(.teal)

                            VStack(alignment: .leading) {
                                Text("Rol activo: Jurado Calificador")
                                    .font(.headline)
                                Text("Evaluación de proyectos asignados")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        HStack(spacing: 8) {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.secondary)
                            Text("Tus calificaciones se sincronizan automáticamente al tener conexión.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    if let errorMessage = fairsStore.errorMessage {
                        ErrorBanner(message: errorMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Sección: EN CURSO
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("EN CURSO")
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(fairsStore.activeFairs.count) activa")
                                .font(.caption)
                                .foregroundColor(.teal)
                        }

                        if fairsStore.isLoading {
                            ProgressView("Cargando ferias...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else if fairsStore.activeFairs.isEmpty {
                            Text("No tienes ferias activas asignadas.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(fairsStore.activeFairs) { assignment in
                                Button {
                                    path.append(.declaration(fairId: assignment.fair.id))
                                } label: {
                                    FairItemRow(fair: assignment.fair)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Sección: CERRADAS
                    if !fairsStore.closedFairs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("CERRADAS")
                                    .font(.caption).bold()
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Histórico")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            ForEach(fairsStore.closedFairs) { assignment in
                                Button {
                                    path.append(.declaration(fairId: assignment.fair.id))
                                } label: {
                                    FairItemRow(fair: assignment.fair)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Banner Guía
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.teal)
                        Text("¿Tienes dudas sobre los criterios de rúbrica?")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Button("Ver Guía") {}
                            .font(.caption).bold()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Ferias")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: FairRoute.self) { route in
                switch route {
                case .declaration(let fairId):
                    DeclarationView(
                        fairId: fairId,
                        onSigned: {
                            path = [.projects(fairId: fairId)]
                        },
                        onBack: {
                            path.removeLast()
                        }
                    )
                case .projects(let fairId):
                    ProjectListView(fairId: fairId)
                }
            }
.task {
            await fairsStore.fetchMyAssignments()
        }
    }
}

/// Fila de una feria asignada al jurado.
private struct FairItemRow: View {
    let fair: Fair

    private var statusLabel: String {
        fair.status.uppercased()
    }

    private var statusColor: Color {
        switch fair.status.uppercased() {
        case "ACTIVE", "PUBLISHED", "OPEN":
            return .green
        case "CLOSED":
            return .gray
        default:
            return .orange
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.columns")
                .font(.title2)
                .foregroundColor(Color.appPrimary)
                .frame(width: 42, height: 42)
                .background(Color.appPrimaryLight)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(fair.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(statusLabel)
                    .font(.caption2).bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
}