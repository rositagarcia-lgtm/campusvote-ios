import SwiftUI

struct FairListView: View {
    @Environment(FairsStore.self) private var fairsStore
    @Environment(SessionStore.self) private var session

    @State private var path: [FairRoute] = []
    @State private var blockedMessage: String?
    @State private var categoriesByFair: [String: [String]] = [:]

    private var institutionName: String {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return fairsStore.organizationName ?? "Institución"
    }

    private var juryName: String {
        if case .signedIn(let user) = session.phase {
            let name = user.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty { return name }
        }
        return "Jurado"
    }

    private var openFairs: [FairAssignment] {
        fairsStore.activeFairs.filter { $0.fair.isOpen }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        welcome

                        if let errorMessage = fairsStore.errorMessage {
                            ErrorBanner(message: errorMessage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if fairsStore.isLoading && fairsStore.activeFairs.isEmpty {
                            ProgressView("Cargando ferias...")
                                .frame(maxWidth: .infinity, minHeight: 180)
                        } else if openFairs.isEmpty {
                            emptyOpen
                        } else {
                            openSection
                                .padding(.top, 6)
                        }

                        if !fairsStore.closedFairs.isEmpty {
                            closedSection
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 26)
                    .padding(.bottom, 28)
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
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
                await loadCategories()
            }
            .refreshable {
                await fairsStore.fetchMyAssignments()
                await loadCategories()
            }
            .alert("Feria no disponible", isPresented: Binding(
                get: { blockedMessage != nil },
                set: { if !$0 { blockedMessage = nil } }
            )) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(blockedMessage ?? "")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            logo
            Text(institutionName)
                .font(.title3.bold())
                .foregroundStyle(Color.onBrand)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

    @ViewBuilder
    private var logo: some View {
        if let url = InstitutionAppearance.logoURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else {
                    logoFallback
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            logoFallback
        }
    }

    private var logoFallback: some View {
        Image(systemName: "building.columns.fill")
            .font(.title3)
            .foregroundStyle(Color.onBrand)
            .frame(width: 40, height: 40)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(Color.appNeutral)
                Text("JURADO CALIFICADOR")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(Color.appNeutral)
            }

            Text("Bienvenido, \(juryName)")
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    private var openSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mis ferias abiertas")
                    .font(.subheadline.weight(.semibold))
                Text("\(openFairs.count) activa\(openFairs.count == 1 ? "" : "s")")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.brand.opacity(0.12)))
                Spacer()
            }

            ForEach(openFairs) { assignment in
                OpenFairCard(
                    fair: assignment.fair,
                    categories: categoriesByFair[assignment.fair.id] ?? [],
                    progress: fairsStore.progressByFair[assignment.fair.id],
                    onEnter: { abrir(assignment.fair) }
                )
            }
        }
    }

    private var emptyOpen: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.columns")
                .font(.system(size: 36))
                .foregroundStyle(Color.brand)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.brand.opacity(0.12)))
            Text("No hay ferias abiertas")
                .font(.headline)
            Text("Cuando tu institución abra una feria asignada, aparecerá aquí.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
    }

    private var closedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CERRADAS")
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)

            ForEach(fairsStore.closedFairs) { assignment in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(assignment.fair.name)
                            .font(.subheadline.weight(.semibold))
                        if let site = assignment.fair.siteName, !site.isEmpty {
                            Label(site, systemImage: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("Cerrada")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.systemGray5)))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
            }
        }
    }

    private func abrir(_ fair: Fair) {
        guard fair.isOpen else {
            blockedMessage = "Solo puedes evaluar una feria abierta."
            return
        }
        if fairsStore.hasSignedDeclaration(fairId: fair.id) {
            path.append(.projects(fairId: fair.id))
        } else {
            path.append(.declaration(fairId: fair.id))
        }
    }

    private func loadCategories() async {
        var map: [String: [String]] = [:]
        for assignment in openFairs {
            guard let projects = try? await APIClient.shared.send(
                .projects(fairId: assignment.fair.id),
                as: [Project].self
            ) else { continue }
            let names = Array(Set(projects.compactMap(\.categoryName))).sorted()
            if !names.isEmpty {
                map[assignment.fair.id] = names
            }
        }
        categoriesByFair = map
    }
}

private struct OpenFairCard: View {
    let fair: Fair
    let categories: [String]
    let progress: JuryProgress?
    let onEnter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Text(fair.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Abierta")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(Color.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.green.opacity(0.14)))
            }

            if let when = dateLine {
                Label(when, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let place = fair.siteName, !place.isEmpty {
                Label(place, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let progress, progress.totalProjects > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(progress.completedProjects) de \(progress.totalProjects) proyectos")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(progress.completedProjects), total: Double(progress.totalProjects))
                        .tint(Color.brand)
                }
            }

            if !categories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORÍAS QUE EVALÚAS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(.secondary)
                    ChipFlow(spacing: 8) {
                        ForEach(categories, id: \.self) { item in
                            Text(item)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.brand)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.brand.opacity(0.12)))
                        }
                    }
                }
            }

            Button(action: onEnter) {
                HStack(spacing: 6) {
                    Text("Ingresar a evaluar")
                        .font(.footnote.weight(.semibold))
                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.semibold))
                }
                .foregroundStyle(Color.onBrand)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
    }

    private var dateLine: String? {
        let start = Self.legible(fair.startsAt)
        let end = Self.legible(fair.endsAt)
        switch (start, end) {
        case let (start?, end?):
            return "\(start) – \(end)"
        case let (start?, nil):
            return start
        case let (nil, end?):
            return end
        default:
            return nil
        }
    }

    private static func legible(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let withMillis = ISO8601DateFormatter()
        withMillis.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        guard let date = withMillis.date(from: raw) ?? plain.date(from: raw) else { return raw }
        return date.formatted(Date.FormatStyle().day().month(.wide).year().locale(Locale(identifier: "es_PE")))
    }
}

private struct ChipFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
