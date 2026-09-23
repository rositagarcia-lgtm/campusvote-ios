import SwiftUI

/// Pantalla de inicio del jurado: sus ferias asignadas, en curso y cerradas.
/// La cabecera muestra la institución y la sede que manda el backend en
/// /fairs/my-assignments, así que un jurado de la UNT ve la UNT y uno de
/// Tecsup ve Tecsup, sin nada escrito a mano.
struct FairListView: View {
    @Environment(FairsStore.self) private var fairsStore

    @State private var path: [FairRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    cabecera
                    rolActivoCard

                    if let errorMessage = fairsStore.errorMessage {
                        ErrorBanner(message: errorMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    seccionEnCurso

                    if !fairsStore.closedFairs.isEmpty {
                        seccionCerradas
                    }

                    bannerGuia
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FairRoute.self) { route in
                switch route {
                case .declaration(let fairId):
                    DeclarationView(
                        fairId: fairId,
                        onSigned: { path = [.projects(fairId: fairId)] },
                        onBack: { path.removeLast() }
                    )
                case .projects(let fairId):
                    ProjectListView(fairId: fairId)
                }
            }
            .task {
                await fairsStore.fetchMyAssignments()
            }
            .refreshable {
                await fairsStore.fetchMyAssignments()
            }
        }
    }

    // MARK: - Cabecera

    private var cabecera: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ferias")
                    .font(.title.bold())

                // Sin institución ni sede no se pinta ni el icono: un alfiler
                // solo, sin texto, parece un error de la app.
                if !ubicacion.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(ubicacion)
                            .font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if fairsStore.hasLiveFair {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("En vivo")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.green.opacity(0.14)))
                .padding(.top, 6)
            }
        }
    }

    /// "Tecsup · Trujillo" cuando el backend manda ambos; si falta algo, se
    /// muestra lo que haya en vez de inventar texto.
    private var ubicacion: String {
        [fairsStore.organizationName, fairsStore.siteName]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    // MARK: - Rol activo

    private var rolActivoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title3)
                    .foregroundStyle(Color.onBrand)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Rol activo: Jurado Calificador")
                        .font(.subheadline.weight(.semibold))
                    Text("Evaluación de proyectos asignados")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.caption)
                    .foregroundStyle(Color.brandTeal)
                Text("Tus calificaciones se sincronizan automáticamente al tener conexión.")
                    .font(.caption.italic())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Secciones

    private var seccionEnCurso: some View {
        VStack(alignment: .leading, spacing: 10) {
            encabezadoSeccion(
                titulo: "EN CURSO",
                derecha: "\(fairsStore.activeFairs.count) activa\(fairsStore.activeFairs.count == 1 ? "" : "s")",
                colorDerecha: Color.brandTeal
            )

            if fairsStore.isLoading && fairsStore.activeFairs.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if fairsStore.activeFairs.isEmpty {
                Text("No tienes ferias activas asignadas.")
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(fairsStore.activeFairs) { assignment in
                    Button {
                        abrir(fairId: assignment.fair.id)
                    } label: {
                        FilaDeFeria(
                            fair: assignment.fair,
                            progress: fairsStore.progressByFair[assignment.fair.id]
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var seccionCerradas: some View {
        VStack(alignment: .leading, spacing: 10) {
            encabezadoSeccion(titulo: "CERRADAS", derecha: "Histórico", colorDerecha: .secondary)

            ForEach(fairsStore.closedFairs) { assignment in
                Button {
                    abrir(fairId: assignment.fair.id)
                } label: {
                    FilaDeFeria(fair: assignment.fair, progress: nil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// La declaración se firma UNA vez por feria: si ya está firmada, se entra
    /// directo a los proyectos en lugar de volver a pedirla.
    private func abrir(fairId: String) {
        if fairsStore.hasSignedDeclaration(fairId: fairId) {
            path.append(.projects(fairId: fairId))
        } else {
            path.append(.declaration(fairId: fairId))
        }
    }

    private func encabezadoSeccion(
        titulo: String,
        derecha: String,
        colorDerecha: Color
    ) -> some View {
        HStack {
            Text(titulo)
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Spacer()
            Text(derecha)
                .font(.caption2)
                .foregroundStyle(colorDerecha)
        }
    }

    // MARK: - Banner de ayuda

    private var bannerGuia: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.title3)
                .foregroundStyle(Color.brandTeal)

            Text("¿Tienes dudas sobre los criterios de rúbrica?")
                .font(.caption)
                .foregroundStyle(.primary)

            Spacer()

            Text("Ver guía")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brand)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.cardBackground))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.iconTile))
    }
}

// MARK: - Fila de una feria

/// Tarjeta de una feria asignada, con su estado y —si el backend ya dio el
/// avance— cuántos proyectos le tocan y cuánto lleva calificado.
private struct FilaDeFeria: View {
    let fair: Fair
    let progress: JuryProgress?

    private var estado: (texto: String, color: Color) {
        switch fair.status.uppercased() {
        case "OPEN":
            return ("Abierta", .green)
        case "CLOSED":
            return ("Cerrada", .secondary)
        default:
            return ("Programada", Color.brandGold)
        }
    }

    private var detalle: String? {
        if let progress {
            let total = progress.totalProjects
            return "\(total) proyecto\(total == 1 ? "" : "s") asignado\(total == 1 ? "" : "s")"
        }
        return fair.description
    }

    private var avance: Double? {
        guard let progress, progress.totalProjects > 0 else { return nil }
        return Double(progress.evaluatedProjects) / Double(progress.totalProjects)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.columns")
                .font(.headline)
                .foregroundStyle(Color.brand)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.brandMint))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(fair.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(estado.texto)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(estado.color.opacity(0.15)))
                        .foregroundStyle(estado.color)
                }

                if let detalle, !detalle.isEmpty {
                    Text(detalle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let avance {
                    ProgressView(value: avance)
                        .tint(Color.brandTeal)
                        .frame(height: 4)
                }
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}
