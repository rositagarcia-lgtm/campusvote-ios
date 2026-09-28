import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    @State private var profile: JuryProfile?
    @State private var localAvatar: UIImage?
    @State private var isLoading = false
    @State private var isLoggingOut = false
    @State private var errorMessage: String?
    @State private var showPhotoMenu = false
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showEdit = false
    @State private var showPassword = false

    private var institutionName: String {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                section(title: "DATOS ACADÉMICOS") {
                    infoRow("Institución", institutionName)
                    Divider()
                    infoRow("Código institucional", profile?.institutionalId ?? "—")
                    Divider()
                    infoRow("Documento", profile?.documentLine ?? "—")
                }

                section(title: "SEGURIDAD Y CUENTA") {
                    actionRow(icon: "person", title: "Editar datos") { showEdit = true }
                    Divider()
                    actionRow(icon: "lock", title: "Cambiar contraseña") { showPassword = true }
                }

                Button(action: logout) {
                    HStack(spacing: 8) {
                        if isLoggingOut {
                            ProgressView()
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        Text("Cerrar sesión")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isLoggingOut)
                .padding(.top, 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showPhotoMenu) {
            PhotoSourceSheet(
                canUseCamera: UIImagePickerController.isSourceTypeAvailable(.camera),
                onGallery: {
                    showPhotoMenu = false
                    showLibrary = true
                },
                onCamera: {
                    showPhotoMenu = false
                    showCamera = true
                }
            )
            .presentationDetents([.height(230)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(12)
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
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(12)
            }
        }
        .sheet(isPresented: $showPassword) {
            ChangePasswordSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(12)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                avatar
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.cardBackground, lineWidth: 4))

                Button {
                    showPhotoMenu = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.onBrand)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.brand))
                        .overlay(Circle().stroke(Color.cardBackground, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cambiar foto de perfil")
            }

            if let profile {
                Text(profile.fullName)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text(profile.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if isLoading {
                ProgressView()
            }

            Text("JURADO EVALUADOR OFICIAL")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.brand)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.brand.opacity(0.15)))
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var avatar: some View {
        if let localAvatar {
            Image(uiImage: localAvatar)
                .resizable()
                .scaledToFill()
        } else if let url = profile?.avatarURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholderAvatar
            }
        } else {
            placeholderAvatar
        }
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.gray.opacity(0.35))
            .background(Circle().fill(Color.cardBackground))
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14)
    }

    private func actionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func load() async {
        isLoading = profile == nil
        errorMessage = nil
        defer { isLoading = false }
        localAvatar = ProfileAvatarStore.load()
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
        ProfileAvatarStore.save(image)
    }

    private func logout() {
        isLoggingOut = true
        Task { await session.logout() }
    }
}

private struct PhotoSourceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let canUseCamera: Bool
    let onGallery: () -> Void
    let onCamera: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Foto de perfil")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar")
            }
            .padding(.bottom, 8)

            Button(action: onGallery) {
                Label("Galería", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if canUseCamera {
                Divider()
                Button(action: onCamera) {
                    Label("Tomarse foto", systemImage: "camera")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.cardBackground)
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
        NavigationStack {
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
                            .font(.footnote)
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
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Editar datos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .accessibilityLabel("Cerrar")
                }
            }
        }
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
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "lock")
                    .font(.caption)
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield")
                            .font(.title3)
                            .foregroundStyle(Color.brand)
                            .frame(width: 40, height: 40)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.12)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seguridad de la cuenta").font(.subheadline.bold())
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
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text("La contraseña debe contener un mínimo de 8 caracteres, al menos una mayúscula, una minúscula, un número y un símbolo especial.")
                            .font(.footnote)
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
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .accessibilityLabel("Cerrar")
                }
            }
        }
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
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("jury-profile-avatar.jpg")
    }

    static func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
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
