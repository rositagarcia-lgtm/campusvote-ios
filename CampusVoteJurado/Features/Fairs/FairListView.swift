import SwiftUI

struct FairListView: View {
    @Environment(\.locale) private var locale
    @Environment(FairsStore.self) private var fairsStore
    @Environment(SessionStore.self) private var session
    @State private var path: [String] = []
    @State private var showContent = false

    private var institutionName: String {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return fairsStore.organizationName ?? L10n.tr("Institución", locale: locale)
    }

    private var greetingName: String {
        guard case .signedIn(let user) = session.phase else { return L10n.tr("Jurado", locale: locale) }
        let first = user.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = user.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !last.isEmpty, first.localizedCaseInsensitiveContains(last) {
            return first
        }
        return user.fullName
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                FairListHeaderView(institutionName: institutionName)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("JURADO CALIFICADOR")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(0.6)
                            }
                            .foregroundStyle(Color.brand)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.brand.opacity(0.1))
                            .clipShape(Capsule())

                            Text(L10n.format("Bienvenido, %@", locale: locale, greetingName))
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.brand)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)

                        if let errorMessage = fairsStore.errorMessage {
                            ErrorBanner(message: errorMessage)
                                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                        }

                        VStack(spacing: 32) {
                            seccionAbiertas
                            seccionProgramadas
                            seccionCerradas
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .refreshable {
                    await fairsStore.fetchMyAssignments()
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { fairId in
                ProjectListView(fairId: fairId)
            }
            .task {
                await fairsStore.fetchMyAssignments()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showContent = true
                    }
                }
            }
        }
    }

    private var seccionAbiertas: some View {
        FairsSectionView(
            title: "ABIERTAS",
            count: fairsStore.activeFairs.count,
            isHighlighted: true,
            isEmpty: fairsStore.activeFairs.isEmpty,
            isLoading: fairsStore.isLoading && fairsStore.activeFairs.isEmpty,
            emptyTitle: "No hay ferias abiertas",
            emptyMessage: "Cuando tu institución abra una feria asignada, aparecerá aquí.",
            emptyIcon: "calendar.badge.clock"
        ) {
            ForEach(fairsStore.activeFairs) { assignment in
                Button {
                    path.append(assignment.fair.id)
                } label: {
                    FilaDeFeria(fair: assignment.fair, status: .open)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var seccionProgramadas: some View {
        FairsSectionView(
            title: "PROGRAMADAS",
            count: fairsStore.scheduledFairs.count,
            isHighlighted: false,
            isEmpty: fairsStore.scheduledFairs.isEmpty,
            isLoading: false,
            emptyTitle: "No hay ferias programadas",
            emptyMessage: "Las ferias que todavía no abren aparecen aquí.",
            emptyIcon: "calendar"
        ) {
            ForEach(fairsStore.scheduledFairs) { assignment in
                FilaDeFeria(fair: assignment.fair, status: .scheduled)
            }
        }
    }

    private var seccionCerradas: some View {
        FairsSectionView(
            title: "CERRADAS",
            count: fairsStore.closedFairs.count,
            isHighlighted: false,
            isEmpty: fairsStore.closedFairs.isEmpty,
            isLoading: false,
            emptyTitle: "No hay ferias cerradas",
            emptyMessage: "Cuando una feria termine, queda en esta lista.",
            emptyIcon: "lock.shield"
        ) {
            ForEach(fairsStore.closedFairs) { assignment in
                FilaDeFeria(fair: assignment.fair, status: .closed)
            }
        }
    }
}
