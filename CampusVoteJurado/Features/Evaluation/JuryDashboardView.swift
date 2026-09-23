import SwiftUI

/// Pantalla principal del jurado con su barra inferior: Ferias / Mi avance / Perfil.
/// La pestaña "Ferias" concentra el diseño completo: avance, pendientes y recién calificados.
struct JuryDashboardView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FairsDashboardView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Ferias", systemImage: "building.columns.fill") }
            .tag(0)

            NavigationStack {
                AdvanceDashboardView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Mi avance", systemImage: "chart.pie.fill") }
            .tag(1)

            NavigationStack {
                SearchView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
            .tag(2)

            NavigationStack {
                ProfileDashboardView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Perfil", systemImage: "person.crop.circle.fill") }
            .tag(3)
        }
        .tint(JuryTheme.brand)
    }
}

// MARK: - Pestaña Ferias (diseño principal)

/// La feria en curso con el resumen "Mi avance" y las listas de pendientes y calificados.
struct FairsDashboardView: View {
    @Environment(SessionStore.self) private var session
    @Environment(FairsStore.self) private var fairs
    @Environment(ProjectsStore.self) private var projects
    @Environment(EvaluationStore.self) private var evaluation

    private var fair: Fair? { fairs.activeFairs.first?.fair }
    private var progress: JuryProgress? { evaluation.progress }

    private var evaluatedIds: Set<String> {
        Set((progress?.evaluations ?? []).map(\.projectId))
    }

    private var pending: [ProjectCard] {
        projects.projects.filter { !evaluatedIds.contains($0.id) }
    }

    private var evaluated: [Evaluation] {
        progress?.evaluations ?? []
    }

    private var averageScore: Double? {
        let items = evaluated.map(\.totalScore)
        guard !items.isEmpty else { return nil }
        return items.reduce(0, +) / Double(items.count)
    }

    private var maxTotal: Double {
        evaluation.rubric?.criteria.reduce(0) { $0 + $1.maxScore } ?? 20
    }

    private func standCode(for projectId: String) -> String? {
        projects.projects.first { $0.id == projectId }?.standCode
    }

    private func sign(for user: User?) -> String {
        guard let user else { return "?" }
        let first = user.firstName.prefix(1)
        let last = user.lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DashboardHeader(initials: sign(for: sessionUser))
                DashboardHero(fairName: fair?.name ?? "Feria de Proyectos 2026")

                JurySummaryCard(
                    progress: progress,
                    averageScore: averageScore,
                    maxTotal: maxTotal
                )

                JurySectionHeader(
                    title: "PENDIENTES (\(pending.count))",
                    trailing: "Por orden de stand"
                ) {
                    if !pending.isEmpty {
                        ForEach(pending) { project in
                            PendingProjectRow(project: project)
                        }
                    } else {
                        Text("No quedan proyectos por calificar.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    }
                }

                JurySectionHeader(
                    title: "CALIFICADOS RECIENTEMENTE (\(evaluated.count))",
                    trailing: "Acta sincronizada",
                    trailingSystemImage: "checkmark.circle.fill"
                ) {
                    if !evaluated.isEmpty {
                        ForEach(evaluated) { item in
                            EvaluatedProjectRow(
                                item: item,
                                standCode: standCode(for: item.projectId),
                                evaluatedAt: item.updatedAt
                            )
                        }
                    } else {
                        Text("Aquí aparecerán tus calificaciones.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    }
                }

                FooterNote()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .task { await load() }
        .refreshable { await load() }
    }

    private var sessionUser: User? {
        if case .signedIn(let user) = session.phase {
            return user
        }
        return nil
    }

    private func load() async {
        await fairs.fetchMyAssignments()
        guard let fair = fairs.activeFairs.first?.fair else { return }
        await projects.open(fairId: fair.id)
        await projects.load(fairId: fair.id)
        await evaluation.load(fairId: fair.id)
    }
}

// MARK: - Pestaña Mi avance

/// Resumen global de la feria: el total de calificaciones y la lista de todas las notas.
struct AdvanceDashboardView: View {
    @Environment(FairsStore.self) private var fairs
    @Environment(EvaluationStore.self) private var evaluation

    private var fair: Fair? { fairs.activeFairs.first?.fair }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DashboardHero(fairName: fair?.name ?? "Feria de Proyectos 2026")

                JurySummaryCard(progress: evaluation.progress, averageScore: average, maxTotal: maxTotal)

                JurySectionHeader(title: "TODAS MIS NOTAS") {
                    if let progress = evaluation.progress {
                        ForEach(progress.evaluations ?? []) { item in
                            EvaluatedProjectRow(
                                item: item,
                                standCode: nil,
                                evaluatedAt: item.updatedAt
                            )
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await fairs.fetchMyAssignments()
            if let fair = fairs.activeFairs.first?.fair {
                await evaluation.refreshProgress(fairId: fair.id)
            }
        }
    }

    private var average: Double? {
        guard let items = evaluation.progress?.evaluations?.map(\.totalScore), !items.isEmpty else { return nil }
        return items.reduce(0, +) / Double(items.count)
    }

    private var maxTotal: Double {
        evaluation.rubric?.criteria.reduce(0) { $0 + $1.maxScore } ?? 20
    }
}

// MARK: - Pestaña Perfil

/// Perfil del jurado con su rol, organización y salida de sesión.
struct ProfileDashboardView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = sessionUser {
                    VStack(spacing: 12) {
                        ProfileCircle(initials: initials(for: user), size: 88)
                        VStack(spacing: 4) {
                            Text(user.fullName)
                                .font(.title3.bold())
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Chip(
                            text: "JURADO",
                            background: JuryTheme.mint,
                            textColor: JuryTheme.mintText
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 24).fill(.white))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)

                    VStack(alignment: .leading, spacing: 10) {
                        ProfileRow(label: "Organización", value: user.organizationId ?? "Tecsup")
                        Divider()
                        ProfileRow(label: "Rol", value: user.role)
                        Divider()
                        ProfileRow(label: "Usuario", value: user.id)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 20).fill(.white))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)

                    FooterNote()

                    Button(role: .destructive) {
                        Task { await session.logout() }
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                    }
                    .buttonStyle(.plain)
                } else {
                    ProgressView()
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var sessionUser: User? {
        if case .signedIn(let user) = session.phase {
            return user
        }
        return nil
    }

    private func initials(for user: User) -> String {
        "\(user.firstName.prefix(1))\(user.lastName.prefix(1))".uppercased()
    }
}

/// Fila de perfil: etiqueta a la izquierda y valor a la derecha.
private struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Encabezado

/// Marca, título de la pestaña e icono de perfil.
struct DashboardHeader: View {
    let initials: String

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                JuryTypography.eyebrow("CAMPUSVOTE · JURADO")
                    .foregroundStyle(.secondary)
                Text("Ferias")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
            }
            Spacer()
            ProfileCircle(initials: initials)
        }
    }
}

/// Feria en curso y título grande "Mi avance".
struct DashboardHero: View {
    let fairName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(fairName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            JuryTypography.display("Mi avance")
                .foregroundStyle(JuryTheme.brandDeep)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Avatar circular con las iniciales del usuario.
struct ProfileCircle: View {
    let initials: String
    var size: CGFloat = 44

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(JuryTheme.brand))
    }
}

// MARK: - Tarjeta de resumen

/// Aro de progreso con el conteo y el porcentaje en el centro.
struct ProgressRing: View {
    let value: Double
    let total: Double

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(JuryTheme.mint, lineWidth: 11)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    JuryTheme.brand,
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(Int(value))/\(Int(total))")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(JuryTheme.brandDeep)
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 108, height: 108)
    }
}

/// Tarjeta blanca "Mi avance": aro, texto, tiempo estimado y dos métricas.
struct JurySummaryCard: View {
    let progress: JuryProgress?
    let averageScore: Double?
    let maxTotal: Double

    private var evaluated: Int { progress?.evaluatedProjects ?? 0 }
    private var total: Int { progress?.totalProjects ?? 0 }
    private var remaining: Int { progress?.remaining ?? 0 }

    private var estimatedMinutes: Int {
        Int((Double(remaining) * 9).rounded())
    }

    private var averageText: String {
        guard let averageScore else { return "—" }
        return averageScore.formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 18) {
                ProgressRing(value: Double(evaluated), total: Double(total))
                VStack(alignment: .leading, spacing: 6) {
                    Text(remaining == 0 ? "¡Completaste todas las evaluaciones!" : "Te quedan \(remaining) proyectos por calificar")
                        .font(.headline)
                        .foregroundStyle(JuryTheme.brandDeep)
                    Label(
                        "Tiempo estimado restante: ~\(estimatedMinutes) min",
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            Divider()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Promedio otorgado")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(averageText)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(JuryTheme.brandDeep)
                        Text("/ \(Int(maxTotal))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Mesa asignada")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text("Mesa 04")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(JuryTheme.brandDeep)
                        ACTIVABadge()
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

/// Badge dorado/marrón de estado ACTIVA.
struct ACTIVABadge: View {
    var body: some View {
        Text("ACTIVA")
            .font(.system(size: 10, weight: .black))
            .tracking(0.5)
            .foregroundStyle(JuryTheme.goldDeep)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(JuryTheme.gold.opacity(0.18))
                    .overlay(Capsule().stroke(JuryTheme.gold, lineWidth: 1))
            )
    }
}

// MARK: - Encabezados de sección

/// Título de sección con su recuento y una acción o nota a la derecha.
struct JurySectionHeader<Content: View>: View {
    let title: String
    var trailing: String? = nil
    var trailingSystemImage: String? = nil
    @ViewBuilder let content: Content

    init(
        title: String,
        trailing: String? = nil,
        trailingSystemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.trailing = trailing
        self.trailingSystemImage = trailingSystemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .tracking(0.3)
                Spacer()
                if let trailing {
                    HStack(spacing: 4) {
                        if let trailingSystemImage {
                            Image(systemName: trailingSystemImage)
                        }
                        Text(trailing)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(JuryTheme.mintText)
                }
            }
            content
        }
    }
}

/// Chip pequeño redondeado para categorías, stands y estados.
struct Chip: View {
    let text: String
    var background: Color
    var textColor: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(background))
    }
}

// MARK: - Tarjeta de proyecto pendiente

/// Proyecto por calificar: portada, nombre, chips de stand y categoría, y chevron.
struct PendingProjectRow: View {
    let project: ProjectCard

    var body: some View {
        HStack(spacing: 14) {
            CoverImage(url: project.coverUrl.flatMap { URL(string: $0) })
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let standCode = project.standCode, !standCode.isEmpty {
                        Chip(text: standCode, background: JuryTheme.mint, textColor: JuryTheme.mintText)
                    }
                    if let category = project.category {
                        Chip(text: category, background: JuryTheme.surface, textColor: .secondary)
                    }
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

// MARK: - Tarjeta de proyecto calificado

/// Proyecto ya evaluado: check verde, nombre, stand y hora, y la nota destacada.
struct EvaluatedProjectRow: View {
    let item: Evaluation
    var standCode: String?
    var evaluatedAt: Date?

    private var subtitle: String {
        var parts: [String] = []
        if let standCode, !standCode.isEmpty {
            parts.append(standCode)
        }
        if let evaluatedAt {
            parts.append("Evaluado \(evaluatedAt.formatted(date: .omitted, time: .shortened))")
        }
        return parts.isEmpty ? "Evaluado" : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(JuryTheme.brand)
                .accessibilityLabel("Calificado")

            VStack(alignment: .leading, spacing: 4) {
                Text(item.project?.name ?? "Proyecto")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(item.totalScore, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .foregroundStyle(JuryTheme.brandDeep)
                Text("/ 20")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

// MARK: - Pie de página

/// Firma digital activa institucional al pie de las listas.
struct FooterNote: View {
    var body: some View {
        Label("Firma digital institucional activa · Tecsup Jurado", systemImage: "checkmark.shield.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }
}

// MARK: - Previews

#Preview {
    VStack(alignment: .leading, spacing: 18) {
        DashboardHeader(initials: "JR")
        DashboardHero(fairName: "Feria de Proyectos 2026")
        JurySummaryCard(
            progress: JuryProgress(
                fairId: "f1",
                fairName: "Feria de Proyectos 2026",
                fairStatus: "ACTIVE",
                declaration: nil,
                totalProjects: 8,
                evaluatedProjects: 3,
                remaining: 5,
                progressPercentage: 37.5,
                evaluations: []
            ),
            averageScore: 15.4,
            maxTotal: 20
        )
        JurySectionHeader(title: "PENDIENTES (5)", trailing: "Por orden de stand") {
            PendingProjectRow(
                project: ProjectCard(
                    id: "p1",
                    name: "Brazo robótico de bajo costo",
                    description: nil,
                    logoUrl: nil,
                    coverUrl: nil,
                    categoryName: "Ingeniería y Tecnología",
                    standCode: "Stand 14"
                )
            )
            EvaluatedProjectRow(
                item: Evaluation(
                    id: "e1",
                    projectId: "p1",
                    totalScore: 16.8,
                    comment: nil,
                    project: ProjectSummary(id: "p1", name: "Sistema hidropónico vertical"),
                    details: [],
                    updatedAt: .now
                ),
                standCode: "Stand 08"
            )
        }
        FooterNote()
    }
    .padding(20)
    .background(Color(.systemGroupedBackground))
}