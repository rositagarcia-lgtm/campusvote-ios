import SwiftUI

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
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
            Text(L10n.tr(title, locale: locale)).font(.subheadline)
            TextField(L10n.tr(title, locale: locale), text: text)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
        }
    }

    private func lockedField(_ title: String, _ value: String, badge: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.tr(title, locale: locale)).font(.subheadline)
                Spacer()
                if let badge {
                    Label(L10n.tr(badge, locale: locale), systemImage: "lock")
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
