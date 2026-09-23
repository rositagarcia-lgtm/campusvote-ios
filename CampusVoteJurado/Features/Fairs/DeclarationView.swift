import SwiftUI

struct DeclarationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(FairsStore.self) private var fairsStore
    @Environment(TabBarVisibility.self) private var tabBar
    @State private var viewModel: DeclarationViewModel
    var onSigned: () -> Void
    var onBack: () -> Void

    init(
        fairId: String,
        onSigned: @escaping () -> Void,
        onBack: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: DeclarationViewModel(fairId: fairId))
        self.onSigned = onSigned
        self.onBack = onBack
    }

    /// Institución dueña de la feria, tal como la manda el backend.
    private var institucion: String {
        (fairsStore.activeFairs + fairsStore.closedFairs)
            .first { $0.fair.id == viewModel.fairId }?
            .fair.organization?.name ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                // MARK: - Top Header Bar
                HStack {
                    Button(action: { onBack() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Ferias")
                                .font(.subheadline)
                                .bold()
                        }
                        .foregroundColor(Color.appPrimary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("JURADO EVALUADOR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }

                // MARK: - Title & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text("Declaración de conflicto de interés")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)

                    Text("Conformidad académica previa a la asignación de rúbricas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: - Main Legal Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.appPrimaryLight)
                                .frame(width: 40, height: 40)
                            Image(systemName: "scale.3d")
                                .font(.system(size: 18))
                                .foregroundColor(Color.appPrimary)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                            Text(institucion.isEmpty
                                 ? "CÓDIGO JURÍDICO"
                                 : "CÓDIGO JURÍDICO \(institucion.uppercased())")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#7A5E0B"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appTertiaryLight)
                        .cornerRadius(6)
                    }

                    // Banner Image
                    ZStack(alignment: .bottomLeading) {
                        Image("banner_principal")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Color.black.opacity(0.25)
                                    .cornerRadius(12)
                            )

                        HStack(spacing: 6) {
                            Image(systemName: "square.and.pencil")
                                .font(.caption2)
                            Text("Dirección Académica y Tribunal Electoral")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(10)
                    }

                    Text("Antes de calificar, declara que no tienes vínculo con los proyectos que te asignaron: no eres su asesor, familiar ni integrante de ningún equipo.")
                        .font(.system(size: 12.5))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 10) {
                        ChecklistRow(text: "Sin parentesco hasta 4to grado de consanguinidad ni 2do de afinidad con los alumnos expositores.")
                        ChecklistRow(text: "No haber intervenido como docente asesor directo, tutor o patrocinador del prototipo en concurso.")
                        ChecklistRow(text: "Compromiso formal de imparcialidad, ética profesional y objetividad según el reglamento de evaluación\(institucion.isEmpty ? "" : " de \(institucion)").")
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                // MARK: - Toggle Card
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appPrimaryLight)
                            .frame(width: 40, height: 40)
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18))
                            .foregroundColor(Color.appPrimary)
                    }

                    Text("Declaro no tener conflicto\nde interés")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.appPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Toggle("", isOn: $viewModel.isToggled)
                        .labelsHidden()
                        .tint(Color.appPrimary)
                        .disabled(viewModel.signedAtDate != nil)
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                // MARK: - Status Info & Date
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Se firma una vez por asignación y queda registrada con fecha y hora.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let signedDate = viewModel.signedAtDate {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(Color.appPrimary)
                            Text(signedDate)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }

                // MARK: - Juror Profile Card
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 42, height: 42)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.jurorName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Text(viewModel.jurorRole)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(14)

                // MARK: - Error Banner
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())

        // MARK: - Bottom Fixed Button Container
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(action: {
                    Task { @MainActor in
                        let success = await viewModel.submitDeclaration()
                        if success {
                            onSigned()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isSigning {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(viewModel.signedAtDate != nil ? "Continuar" : "Firmar y continuar")
                                .font(.system(size: 15, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.isToggled ? Color.appPrimary : Color.appNeutral.opacity(0.4))
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isToggled || viewModel.isSigning)

                Text("Certificado con cifrado de integridad institucional\(institucion.isEmpty ? "" : " \(institucion)")")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -4)
            )
        }
        .task {
            if case .signedIn(let user) = session.phase {
                viewModel.jurorName = user.fullName
            }
            await viewModel.fetchDeclarationStatus()
        }
        // La declaración se firma sin la barra inferior; al salir vuelve.
        .onAppear { tabBar.isHidden = true }
        .onDisappear { tabBar.isHidden = false }
    }
}
