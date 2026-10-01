import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(FairsStore.self) private var fairsStore
    @Environment(ProjectsStore.self) private var projectsStore
    @Environment(TabBarVisibility.self) private var tabBar

    @State private var profile: JuryProfile?
    @State private var localAvatar: UIImage?
    @State private var isLoading = false
    @State private var isLoggingOut = false
    @State private var errorMessage: String?
    @State private var showPhotoMenu = false
    @State private var showInstitution = false
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showEdit = false
    @State private var showPassword = false
    @State private var avatarHidden = ProfileAvatarStore.isHidden

    private var activeFair: Fair? {
        fairsStore.activeFairs.first?.fair
    }

    private var greetingName: String {
        let first = (profile?.firstName ?? signedInUser?.firstName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let last = (profile?.lastName ?? signedInUser?.lastName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if first.isEmpty { return last }
        if last.isEmpty || first.localizedCaseInsensitiveContains(last) { return first }
        return "\(first) \(last)"
    }

    private var initials: String {
        let first = profile?.firstName ?? signedInUser?.firstName ?? ""
        let last = profile?.lastName ?? signedInUser?.lastName ?? ""
        let letters = [first, last].compactMap { $0.first }.map { String($0) }
        let text = letters.joined().uppercased()
        return text.isEmpty ? "·" : text
    }

    private var institutionCode: String {
        let code = profile?.institutionalId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return code.isEmpty ? "—" : code
    }

    private var institutionName: String {
        let name = (fairsStore.organizationName ?? InstitutionAppearance.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "—" : name
    }

    private var institutionSite: String {
        let site = fairsStore.siteName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return site.isEmpty ? "—" : site
    }

    private var institutionBadge: String? {
        switch InstitutionAppearance.kindLabel {
        case "Instituto de Educación Superior": return "Superior"
        case "Universidad": return "Universidad"
        case "Colegio": return "Colegio"
        case "Empresa": return "Empresa"
        case "Asociación": return "Asociación"
        default:
            let label = InstitutionAppearance.kindLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return label.isEmpty ? nil : label
        }
    }

    private var focusCategory: String? {
        let names = projectsStore.pending.compactMap(\.categoryName).filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }
        let counts = Dictionary(grouping: names, by: { $0 }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    private var pendingLine: String {
        let count = projectsStore.summary.pending
        if projectsStore.isLoading && projectsStore.projects.isEmpty {
            return "Cargando proyectos..."
        }
        let proyecto = count == 1 ? "proyecto" : "proyectos"
        let pendiente = count == 1 ? "pendiente" : "pendientes"
        if count == 0 {
            return "No tienes proyectos pendientes."
        }
        if let focusCategory {
            return "Tienes \(count) \(proyecto) \(pendiente) en \(focusCategory)."
        }
        return "Tienes \(count) \(proyecto) \(pendiente)."
    }

    private var progressValue: CGFloat {
        let total = projectsStore.summary.total
        guard total > 0 else { return 0 }
        return CGFloat(projectsStore.summary.rated) / CGFloat(total)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                bannerCard

                shortcuts

                progressCard

                Text("Perfil")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Button {
                    showPassword = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "lock")
                            .font(.system(size: 18))
                            .foregroundStyle(.primary)
                            .frame(width: 24)
                        Text("Seguridad y Credenciales")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button(action: logout) {
                    HStack(spacing: 8) {
                        if isLoggingOut {
                            ProgressView()
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        Text("Cerrar sesión")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.red.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoggingOut)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await reload() }
        .onChange(of: showPhotoMenu) { _, _ in syncTabBar() }
        .onChange(of: showInstitution) { _, _ in syncTabBar() }
        .onDisappear {
            tabBar.isHidden = false
        }
        .overlay {
            if showPhotoMenu {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { showPhotoMenu = false }

                    PhotoSourceSheet(
                        onClose: { showPhotoMenu = false },
                        onCamera: {
                            showPhotoMenu = false
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCamera = true
                            }
                        },
                        onGallery: {
                            showPhotoMenu = false
                            showLibrary = true
                        },
                        onDelete: {
                            showPhotoMenu = false
                            deleteAvatar()
                        }
                    )
                }
                .ignoresSafeArea()
            }
        }
        .overlay {
            if showInstitution {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { showInstitution = false }

                    InstitutionSheet(
                        code: institutionCode,
                        name: institutionName,
                        site: institutionSite,
                        badge: institutionBadge,
                        onClose: { showInstitution = false }
                    )
                }
                .ignoresSafeArea()
            }
        }
        .photosPicker(isPresented: $showLibrary, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await applyLibraryPhoto(item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                storeAvatar(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showEdit) {
            if let profile {
                EditProfileSheet(profile: profile) { updated in
                    self.profile = updated
                }
                .juryBottomSheet(background: Color.appBackground)
            }
        }
        .sheet(isPresented: $showPassword) {
            ChangePasswordSheet()
                .juryBottomSheet(background: Color.appBackground)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(greetingName.isEmpty ? "¡Hola!" : "¡Hola, \(greetingName)!")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showPhotoMenu = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    avatarFace
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())

                    Circle()
                        .fill(Color(red: 0.22, green: 0.78, blue: 0.38))
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                        .offset(x: 1, y: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cambiar foto de perfil")
        }
    }

    @ViewBuilder
    private var avatarFace: some View {
        if let localAvatar {
            Image(uiImage: localAvatar)
                .resizable()
                .scaledToFill()
        } else if !avatarHidden, let url = profile?.avatarURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                initialsFace
            }
        } else {
            initialsFace
        }
    }

    private var initialsFace: some View {
        Circle()
            .fill(Color.brand)
            .overlay {
                Text(initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
            }
    }

    private var bannerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.brand)

            Image(systemName: "plus")
                .font(.system(size: 84, weight: .ultraLight))
                .foregroundStyle(Color.onBrand.opacity(0.18))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .offset(x: 16)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(activeFair.map { "¡\($0.name)!" } ?? "Sin feria activa")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.onBrand)
                        .lineLimit(2)

                    if activeFair != nil {
                        Text("Evaluando")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(red: 1, green: 0.78, blue: 0.15)))
                    }
                }

                Text(activeFair == nil ? "Cuando haya una feria abierta vas a ver tus proyectos aquí." : pendingLine)
                    .font(.caption)
                    .foregroundStyle(Color.onBrand.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .padding(.trailing, 28)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var shortcuts: some View {
        HStack(spacing: 48) {
            Button {
                showEdit = true
            } label: {
                shortcut(icon: "person", title: "Mis Datos")
            }
            .buttonStyle(.plain)
            .disabled(profile == nil)

            Button {
                showInstitution = true
            } label: {
                shortcut(icon: "building.columns", title: "Institución")
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func shortcut(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.primary)
                .frame(width: 72, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                )
            Text(title)
                .font(.caption2)
                .foregroundStyle(.primary)
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Completa tu evaluación")
                .font(.subheadline.weight(.semibold))
            Text("\(projectsStore.summary.rated) de \(projectsStore.summary.total) proyectos calificados")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.12))
                    Capsule()
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: geo.size.width * progressValue)
                }
            }
            .frame(height: 6)
            .padding(.vertical, 4)

            Text(rubricLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private var rubricLine: String {
        if let focusCategory {
            return "Describe y califica las rúbricas de la categoría \(focusCategory)."
        }
        return "Describe y califica las rúbricas de tu feria."
    }

    private func syncTabBar() {
        tabBar.isHidden = showPhotoMenu || showInstitution
    }

    @MainActor
    private func reload() async {
        if profile == nil, let user = signedInUser {
            profile = JuryProfile(user: user)
        }
        await load()
        if fairsStore.activeFairs.isEmpty && fairsStore.closedFairs.isEmpty {
            await fairsStore.fetchMyAssignments()
        }
        if let fairId = activeFair?.id {
            await projectsStore.load(fairId: fairId)
        }
    }

    @MainActor
    private func load() async {
        isLoading = profile == nil
        errorMessage = nil
        defer { isLoading = false }
        localAvatar = ProfileAvatarStore.load()
        avatarHidden = ProfileAvatarStore.isHidden
        do {
            profile = try await APIClient.shared.send(
                Endpoint(path: "users/me", method: "GET"),
                as: JuryProfile.self
            )
        } catch {
            if let user = signedInUser {
                profile = JuryProfile(user: user)
            }
            errorMessage = error.userMessage
        }
    }

    private var signedInUser: User? {
        if case .signedIn(let user) = session.phase { return user }
        return nil
    }

    private func applyLibraryPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        storeAvatar(image)
    }

    private func storeAvatar(_ image: UIImage) {
        localAvatar = image
        avatarHidden = false
        ProfileAvatarStore.save(image)
    }

    private func deleteAvatar() {
        localAvatar = nil
        avatarHidden = true
        ProfileAvatarStore.delete()
    }

    private func logout() {
        isLoggingOut = true
        Task { await session.logout() }
    }
}

private struct InstitutionSheet: View {
    let code: String
    let name: String
    let site: String
    let badge: String?
    let onClose: () -> Void
    @State private var copied = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Institución")
                            .font(.subheadline.weight(.semibold))
                        Text("Información y sede asignada para evaluación")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.trailing, 36)

                    infoCard(icon: "person.text.rectangle", title: "Código institucional", value: code) {
                        if code != "—" {
                            Button {
                                UIPasteboard.general.string = code
                                copied = true
                            } label: {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.brand)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Copiar código")
                        }
                    }

                    infoCard(icon: "graduationcap", title: "Nombre de la IE", value: name) {
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.cardBackground))
                        }
                    }

                    infoCard(icon: "mappin.and.ellipse", title: "Sede", value: site) {
                        Image(systemName: "mappin.and.ellipse")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 20)
                            .foregroundStyle(Color.brand)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                Spacer(minLength: 12)
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .padding(.trailing, 6)
            .accessibilityLabel("Cerrar")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
            )
        )
    }

    private func infoCard<Accessory: View>(
        icon: String,
        title: String,
        value: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 20)
                .foregroundStyle(Color.brand)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.brand.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
            accessory()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))
    }
}
private struct SheetTopBar: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar")
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }
}

private extension View {
    func juryBottomSheet(height: CGFloat? = nil, background: Color) -> some View {
        let sheet = self
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(12)
            .presentationBackground(background)
        if let height {
            return AnyView(sheet.presentationDetents([.height(height)]))
        }
        return AnyView(sheet.presentationDetents([.large]))
    }
}

private struct PhotoSourceSheet: View {
    let onClose: () -> Void
    let onCamera: () -> Void
    let onGallery: () -> Void
    let onDelete: () -> Void

    private let deleteColor = Color(red: 0.86, green: 0.18, blue: 0.38)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SheetTopBar(title: "Edición de foto", onClose: onClose)

            photoRow(icon: "camera", title: "Tomar una foto", color: .primary, action: onCamera)
            photoRow(icon: "photo", title: "Elegir de la galería", color: .primary, action: onGallery)
            photoRow(icon: "trash", title: "Eliminar foto", color: deleteColor, action: onDelete)
        }
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            Color.cardBackground
                .ignoresSafeArea(edges: .bottom)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
            )
        )
    }

    private func photoRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                Spacer(minLength: 0)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String
    @State private var lastName: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    let profile: JuryProfile
    let onSaved: (JuryProfile) -> Void

    init(profile: JuryProfile, onSaved: @escaping (JuryProfile) -> Void) {
        self.profile = profile
        self.onSaved = onSaved
        _firstName = State(initialValue: profile.firstName)
        _lastName = State(initialValue: profile.lastName)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetTopBar(title: "Editar datos") { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    field("Nombres", text: $firstName)
                    field("Apellidos", text: $lastName)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tipo de documento")
                            .font(.subheadline)
                        Picker("Tipo de documento", selection: .constant(profile.documentKind)) {
                            Text("DNI").tag("DNI")
                            Text("Carné de Extranjería").tag("CE")
                        }
                        .pickerStyle(.segmented)
                        .disabled(true)
                    }

                    lockedField("Número de documento", profile.documentNumber ?? "—")
                    lockedField("Correo electrónico", profile.email, badge: "Bloqueado")

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.brand)
                        Text("El correo y el código institucional los asigna la institución.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.08)))

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    Button(action: save) {
                        Group {
                            if isSaving {
                                ProgressView().tint(Color.onBrand)
                            } else {
                                Text("Guardar")
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.onBrand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand))
                    }
                    .disabled(isSaving || firstName.trimmingCharacters(in: .whitespaces).isEmpty || lastName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline)
            TextField(title, text: text)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
        }
    }

    private func lockedField(_ title: String, _ value: String, badge: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                if let badge {
                    Label(badge, systemImage: "lock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "lock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
        }
    }

    private func save() {
        let names = NameUpdate(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces)
        )
        isSaving = true
        errorMessage = nil
        Task {
            do {
                let saved = try await APIClient.shared.send(
                    Endpoint(path: "users/me", method: "PUT", body: names),
                    as: JuryProfile.self
                )
                onSaved(saved)
                dismiss()
            } catch {
                errorMessage = error.userMessage
                isSaving = false
            }
        }
    }
}

private struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var hasLength: Bool { newPassword.count >= 8 }
    private var hasUpper: Bool { newPassword.contains(where: \.isUppercase) }
    private var hasLower: Bool { newPassword.contains(where: \.isLowercase) }
    private var hasNumber: Bool { newPassword.contains(where: \.isNumber) }
    private var hasSymbol: Bool { newPassword.contains(where: { !$0.isLetter && !$0.isNumber }) }
    private var canSave: Bool {
        !current.isEmpty && hasLength && hasUpper && hasLower && hasNumber && hasSymbol && newPassword == confirm && !isSaving
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetTopBar(title: "Contraseña") { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield")
                            .font(.title3)
                            .foregroundStyle(Color.brand)
                            .frame(width: 40, height: 40)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.12)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seguridad de la cuenta").font(.subheadline.weight(.semibold))
                            Text("Jurado Evaluador Institucional")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))

                    secretField("Contraseña actual", text: $current, visible: $showCurrent, prompt: "Ingresa tu contraseña actual")
                    secretField("Nueva contraseña", text: $newPassword, visible: $showNew, prompt: "Ingresa tu nueva contraseña")
                    secretField("Confirmar nueva contraseña", text: $confirm, visible: $showConfirm, prompt: "Repite la nueva contraseña")

                    VStack(alignment: .leading, spacing: 8) {
                        Label("REQUISITOS DE SEGURIDAD", systemImage: "clock")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("La contraseña debe contener un mínimo de 8 caracteres, al menos una mayúscula, una minúscula, un número y un símbolo especial.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        requirement("8+ caracteres", met: hasLength)
                        requirement("Mayúscula y minúscula", met: hasUpper && hasLower)
                        requirement("Al menos 1 número", met: hasNumber)
                        requirement("Símbolo especial", met: hasSymbol)
                        if !confirm.isEmpty && confirm != newPassword {
                            Text("La confirmación no coincide.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    Button(action: save) {
                        Group {
                            if isSaving {
                                ProgressView().tint(Color.onBrand)
                            } else {
                                Text("Guardar contraseña")
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.onBrand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand))
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.6)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground)
    }

    private func secretField(_ title: String, text: Binding<String>, visible: Binding<Bool>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline)
            HStack {
                Group {
                    if visible.wrappedValue {
                        TextField(prompt, text: text)
                    } else {
                        SecureField(prompt, text: text)
                    }
                }
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                Button {
                    visible.wrappedValue.toggle()
                } label: {
                    Image(systemName: visible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
        }
    }

    private func requirement(_ title: String, met: Bool) -> some View {
        Label(title, systemImage: met ? "checkmark.circle.fill" : "circle")
            .font(.caption)
            .foregroundStyle(met ? Color.brand : .secondary)
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        let body = PasswordUpdate(currentPassword: current, newPassword: newPassword)
        Task {
            do {
                try await APIClient.shared.send(
                    Endpoint(path: "users/me/password", method: "POST", body: body)
                )
                dismiss()
            } catch {
                errorMessage = error.userMessage
                isSaving = false
            }
        }
    }
}

private struct JuryProfile: Decodable {
    var firstName: String
    var lastName: String
    let email: String
    let institutionalId: String?
    let documentType: String?
    let documentNumber: String?
    let avatarUrl: String?

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var avatarURL: URL? {
        guard let avatarUrl, let url = URL(string: avatarUrl) else { return nil }
        return url
    }

    var documentKind: String {
        let raw = (documentType ?? "").uppercased()
        if raw.contains("CE") || raw.contains("EXTRAN") { return "CE" }
        return "DNI"
    }

    var documentLine: String {
        let number = documentNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !number.isEmpty else { return "—" }
        let kind = documentType?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let kind, !kind.isEmpty { return "\(kind) \(number)" }
        return number
    }

    init(user: User) {
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        institutionalId = nil
        documentType = nil
        documentNumber = nil
        avatarUrl = nil
    }

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case institutionalId = "institutional_id"
        case documentType = "document_type"
        case documentNumber = "document_number"
        case avatarUrl = "avatar_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        institutionalId = try container.decodeIfPresent(String.self, forKey: .institutionalId)
        documentType = try container.decodeIfPresent(String.self, forKey: .documentType)
        documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
    }
}

private struct NameUpdate: Encodable {
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

private struct PasswordUpdate: Encodable {
    let currentPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}

private enum ProfileAvatarStore {
    private static let hiddenKey = "campusvote.jury.avatar.hidden"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("jury-profile-avatar.jpg")
    }

    static var isHidden: Bool {
        UserDefaults.standard.bool(forKey: hiddenKey)
    }

    static func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: fileURL, options: .atomic)
        UserDefaults.standard.set(false, forKey: hiddenKey)
    }

    static func load() -> UIImage? {
        guard !isHidden, let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
        UserDefaults.standard.set(true, forKey: hiddenKey)
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
