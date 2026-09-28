import SwiftUI

struct ProjectListView: View {
    @State private var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(FairsStore.self) private var fairsStore

    var showsFairsBack: Bool = true

    private var tealDark: Color { Color.brand }
    private var tealLight: Color { Color.brand.opacity(0.15) }
    private let goldBadgeBg = Color(red: 0.99, green: 0.95, blue: 0.82)
    private let goldBadgeTxt = Color(red: 0.55, green: 0.40, blue: 0.05)
    private var bannerBg: Color { Color.brand }

    private var tituloInstitucion: String {
        let nombre = (fairsStore.activeFairs + fairsStore.closedFairs)
            .first { $0.fair.id == viewModel.fairId }?
            .fair.organization?.name
        if let nombre, !nombre.isEmpty {
            return "\(nombre.uppercased()) · EVALUACIÓN OFICIAL"
        }
        return "EVALUACIÓN OFICIAL"
    }

    init(fairId: String, showsFairsBack: Bool = true) {
        _viewModel = State(initialValue: ProjectsViewModel(fairId: fairId))
        self.showsFairsBack = showsFairsBack
    }

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                if showsFairsBack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Ferias")
                                .font(.subheadline).bold()
                        }
                        .foregroundColor(tealDark)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tituloInstitucion)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(tealDark)

                        Text(viewModel.fairName)
                            .font(.title2).bold()
                            .foregroundColor(.primary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(tealDark)
                                .frame(width: 6, height: 6)
                            Text(viewModel.juryTable)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    HStack(spacing: 0) {
                        TabSegmentButton(
                            title: "Pendientes",
                            count: viewModel.remainingCount,
                            isSelected: viewModel.selectedTab == .pending,
                            activeColor: tealDark,
                            activeBadgeColor: tealLight
                        ) {
                            viewModel.selectedTab = .pending
                        }

                        TabSegmentButton(
                            title: "Calificados",
                            count: viewModel.evaluatedCount,
                            isSelected: viewModel.selectedTab == .evaluated,
                            activeColor: tealDark,
                            activeBadgeColor: tealLight
                        ) {
                            viewModel.selectedTab = .evaluated
                        }
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    if viewModel.isLoading {
                        ProgressView("Cargando proyectos...")
                            .frame(maxWidth: .infinity, minHeight: 150)
                    } else {
                        let currentList = viewModel.selectedTab == .pending ? viewModel.pendingProjects : viewModel.evaluatedProjects

                        if currentList.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(tealDark)
                                Text(viewModel.selectedTab == .pending ? "No hay proyectos pendientes" : "Aún no has calificado ningún proyecto")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 180)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(currentList) { project in
                                    NavigationLink(
                                        destination: ProjectDetailView(
                                            fairId: viewModel.fairId,
                                            projectId: project.id
                                        )
                                    ) {
                                        ProjectRowCard(
                                            project: project,
                                            isEvaluated: viewModel.selectedTab == .evaluated,
                                            goldBg: goldBadgeBg,
                                            goldTxt: goldBadgeTxt,
                                            tealBg: tealLight,
                                            tealTxt: tealDark
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Text("Toca un proyecto para ver el detalle, la rúbrica y el voto.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: "timer")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Faltan \(viewModel.remainingCount) proyectos")
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                            Text("Tiempo estimado: \(viewModel.remainingCount * 9) min")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        Text("EN CURSO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(tealDark)
                            .clipShape(Capsule())
                    }
                    .padding()
                    .background(bannerBg)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.loadProjects()
        }
    }
}
