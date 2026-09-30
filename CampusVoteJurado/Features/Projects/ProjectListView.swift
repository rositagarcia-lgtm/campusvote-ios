import SwiftUI

/// Lista de proyectos de la feria, después de firmar la declaración.
/// El buscador vive aquí: categoría, stand y texto, sobre los proyectos del jurado.
struct ProjectListView: View {
    @State private var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(TabBarVisibility.self) private var tabBar

    var showsFairsBack: Bool = true

    @State private var search = ""
    @State private var categoryId: String?
    @State private var standId: String?
    @State private var showFilters = false

    init(fairId: String, showsFairsBack: Bool = true) {
        _viewModel = State(initialValue: ProjectsViewModel(fairId: fairId))
        self.showsFairsBack = showsFairsBack
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    titulo

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    barraBusqueda
                    chipsCategorias

                    if viewModel.isLoading && viewModel.projects.isEmpty {
                        ProgressView("Cargando proyectos...")
                            .frame(maxWidth: .infinity, minHeight: 180)
                    } else if visibles.isEmpty {
                        vacio
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(visibles) { item in
                                NavigationLink {
                                    ProjectDetailView(
                                        fairId: viewModel.fairId,
                                        projectId: item.project.id,
                                        onSaved: {
                                            Task { await viewModel.loadProjects() }
                                        }
                                    )
                                } label: {
                                    ProjectAssignedCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !viewModel.projects.isEmpty {
                        cierre
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .refreshable {
                await viewModel.loadProjects()
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadProjects()
        }
        .onChange(of: showFilters) { _, abierto in
            tabBar.isHidden = abierto
        }
        .onDisappear {
            tabBar.isHidden = false
        }
        .overlay {
            if showFilters {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { showFilters = false }

                    StandFilterSheet(
                        stands: stands,
                        selection: standId,
                        onClose: { showFilters = false },
                        onSelect: { elegido in
                            standId = elegido
                            showFilters = false
                        }
                    )
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Título

    private var titulo: some View {
        HStack(spacing: 8) {
            if showsFairsBack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("Volver")
            }

            Text("Proyectos")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            if !viewModel.projects.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.caption2)
                    Text("\(viewModel.submittedCount) de \(viewModel.projects.count) listos")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(Color.brand)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.brand.opacity(0.12)))
            }
        }
    }

    // MARK: - Buscador

    private var barraBusqueda: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Buscar por proyecto o stand", text: $search)
                    .font(.subheadline)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)

                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Limpiar búsqueda")
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                showFilters = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(standId == nil ? Color.primary : Color.onBrand)
                    .frame(width: 44, height: 44)
                    .background(standId == nil ? Color.cardBackground : Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Filtrar por stand")
        }
    }

    private var chipsCategorias: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "Todas (\(viewModel.projects.count))",
                    isSelected: categoryId == nil
                ) {
                    categoryId = nil
                }

                ForEach(categorias, id: \.id) { category in
                    CategoryChip(
                        title: "\(category.name) (\(category.count))",
                        isSelected: categoryId == category.id
                    ) {
                        categoryId = category.id
                    }
                }
            }
        }
    }

    private var vacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.brand)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.brand.opacity(0.12)))

            Text("No se encontraron proyectos")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Prueba con otro nombre, categoría o stand.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.top, 12)
    }

    private var cierre: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.subheadline)
                .foregroundStyle(Color.brand)

            VStack(alignment: .leading, spacing: 2) {
                Text(textoCierre)
                    .font(.subheadline.weight(.semibold))
                Text("Guarda tus rúbricas antes de que cierre la feria.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brand.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var textoCierre: String {
        if let endsAt = viewModel.endsAt {
            let cuando = Calendar.current.isDateInToday(endsAt)
                ? endsAt.formatted(date: .omitted, time: .shortened)
                : endsAt.formatted(date: .abbreviated, time: .shortened)
            return "Cierre de la feria: \(cuando)"
        }
        let faltan = viewModel.projects.count - viewModel.submittedCount
        if faltan == 0 {
            return "Rúbricas al día"
        }
        return faltan == 1 ? "Te falta 1 proyecto" : "Te faltan \(faltan) proyectos"
    }

    // MARK: - Filtros locales

    private var categorias: [(id: String, name: String, count: Int)] {
        var result: [(id: String, name: String, count: Int)] = []
        for item in viewModel.projects {
            guard let id = item.project.categoryId, let name = item.project.categoryName else { continue }
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index].count += 1
            } else {
                result.append((id: id, name: name, count: 1))
            }
        }
        return result
    }

    private var stands: [(id: String, code: String)] {
        var result: [(id: String, code: String)] = []
        for item in viewModel.projects {
            guard let id = item.project.standId, let code = item.project.standCode, !code.isEmpty else { continue }
            if !result.contains(where: { $0.id == id }) {
                result.append((id: id, code: code))
            }
        }
        return result.sorted { $0.code.localizedStandardCompare($1.code) == .orderedAscending }
    }

    private var visibles: [AssignedProject] {
        let text = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return viewModel.projects.filter { item in
            if let categoryId, item.project.categoryId != categoryId { return false }
            if let standId, item.project.standId != standId { return false }
            if text.isEmpty { return true }
            let blob = [item.project.name, item.project.standCode, item.project.categoryName]
                .compactMap { $0 }
                .joined(separator: " ")
            return blob.localizedStandardContains(text)
        }
    }
}

// MARK: - Chip de categoría

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.onBrand : .primary)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.brand : Color.cardBackground)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tarjeta

private struct ProjectAssignedCard: View {
    let item: AssignedProject

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            portada

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    estado
                    Spacer(minLength: 4)
                    if let stand = item.project.standCode, !stand.isEmpty {
                        Text("Stand \(stand)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(item.project.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let category = item.project.categoryName, !category.isEmpty {
                    Label(category, systemImage: "square.grid.2x2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                accion
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }

    private var portada: some View {
        ZStack(alignment: .bottomLeading) {
            CoverImage(url: item.project.coverUrl.flatMap { URL(string: $0) })
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let sigla = siglaCategoria {
                Text(sigla)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
        }
    }

    private var siglaCategoria: String? {
        guard let name = item.project.categoryName, !name.isEmpty else { return nil }
        let parts = name.split(separator: " ").map(String.init).filter { $0.count > 2 }
        if parts.count >= 2 {
            return parts.prefix(2).compactMap { $0.first }.map { String($0) }.joined().uppercased()
        }
        return String(name.prefix(3)).uppercased()
    }

    @ViewBuilder
    private var estado: some View {
        switch item.phase {
        case .pending:
            pill("Pendiente", foreground: Color.appNeutral, background: Color.appNeutral.opacity(0.14))
        case .draft(let checked, let total):
            let titulo = total > 0 ? "Borrador (\(checked)/\(total))" : "Borrador"
            pill(titulo, foreground: Self.draftText, background: Self.draftBackground)
        case .submitted:
            pill("Enviada", foreground: Self.sentText, background: Self.sentBackground)
        }
    }

    private func pill(_ text: String, foreground: Color, background: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(background))
    }

    @ViewBuilder
    private var accion: some View {
        switch item.phase {
        case .pending:
            HStack {
                Spacer()
                botonLleno("Evaluar")
            }
        case .draft(let checked, let total):
            VStack(alignment: .leading, spacing: 8) {
                if total > 0 {
                    let fraction = min(1, Double(checked) / Double(total))
                    let percent = Int((fraction * 100).rounded())
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Avance de la rúbrica")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(percent)% completado")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.brand)
                        }
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
                }
                HStack {
                    Spacer()
                    botonLleno("Continuar rúbrica")
                }
            }
        case .submitted(let score):
            VStack(alignment: .leading, spacing: 8) {
                if let score {
                    HStack {
                        Text("Tu calificación")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(score.formatted(.number.precision(.fractionLength(0...1)))) / 20")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.brand)
                    }
                }
                HStack {
                    Spacer()
                    botonBorde("Ver rúbrica")
                }
            }
        }
    }

    private func botonLleno(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Color.onBrand)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Color.brand)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func botonBorde(_ title: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text")
                .font(.caption.weight(.semibold))
            Text(title)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Color.brand)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.brand.opacity(0.45), lineWidth: 1)
        )
    }

    private static let draftText = Color(red: 0.62, green: 0.38, blue: 0.05)
    private static let draftBackground = Color(red: 1.0, green: 0.93, blue: 0.78)
    private static let sentText = Color(red: 0.12, green: 0.45, blue: 0.28)
    private static let sentBackground = Color(red: 0.85, green: 0.94, blue: 0.86)
}

// MARK: - Filtro de stand

private struct StandFilterSheet: View {
    let stands: [(id: String, code: String)]
    let selection: String?
    let onClose: () -> Void
    let onSelect: (String?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Stand")
                    .font(.headline)

                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Cerrar")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)

            if stands.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.appNeutral)
                    Text("Sin stands")
                        .font(.subheadline.weight(.semibold))
                    Text("Tus proyectos no traen un stand.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)
            } else {
                fila(icono: "square.grid.2x2", titulo: "Todos", marcado: selection == nil) {
                    onSelect(nil)
                }

                ForEach(stands, id: \.id) { stand in
                    fila(
                        icono: "mappin.and.ellipse",
                        titulo: "Stand \(stand.code)",
                        marcado: selection == stand.id
                    ) {
                        onSelect(stand.id)
                    }
                }
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
            )
            .fill(Color.cardBackground)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func fila(
        icono: String,
        titulo: String,
        marcado: Bool,
        accion: @escaping () -> Void
    ) -> some View {
        Button(action: accion) {
            HStack(spacing: 12) {
                Image(systemName: icono)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.brand)
                    .frame(width: 24)

                Text(titulo)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                if marcado {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brand)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
