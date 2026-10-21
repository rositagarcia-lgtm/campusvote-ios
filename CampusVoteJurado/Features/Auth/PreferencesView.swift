import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FairsStore.self) private var fairsStore
    @Environment(TabBarVisibility.self) private var tabBar

    @AppStorage("campusvote.preferences.appearance") private var appearance = "system"
    @AppStorage("campusvote.preferences.textSize") private var textSize = "normal"
    @AppStorage("campusvote.preferences.language") private var language = "es"

    private var institutionName: String {
        InstitutionAppearance.name ?? fairsStore.organizationName ?? "Institución"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    institutionCard

                    VStack(alignment: .leading, spacing: 14) {
                        sectionTitle("APARIENCIA")
                        darkModeCard
                        textSizeCard
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        sectionTitle("IDIOMA")
                        languageCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 36)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear { tabBar.isHidden = true }
        .onDisappear { tabBar.isHidden = false }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "arrow.left")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Volver a Perfil")

            Text("Configuración")
                .font(.title3.weight(.bold))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var institutionCard: some View {
        HStack(spacing: 14) {
            Group {
                if let url = InstitutionAppearance.logoURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else {
                            Image(systemName: "building.columns")
                                .foregroundStyle(Color.brand)
                        }
                    }
                } else {
                    Image(systemName: "building.columns")
                        .foregroundStyle(Color.brand)
                }
            }
            .frame(width: 56, height: 56)
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.appBackground))

            VStack(alignment: .leading, spacing: 4) {
                Text(institutionName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text("Preferencias del sistema")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Text("v1.0.0")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brand)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.brand.opacity(0.1)))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var darkModeCard: some View {
        HStack(spacing: 14) {
            Image(systemName: appearance == "dark" ? "moon.stars" : "sun.max")
                .font(.title3)
                .foregroundStyle(Color.brand)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.1)))

            VStack(alignment: .leading, spacing: 4) {
                Text("Modo oscuro")
                    .font(.subheadline.weight(.semibold))
                Text(appearance == "system" ? "Sigue la apariencia del dispositivo" : appearance == "dark" ? "Usa un tema oscuro en toda la aplicación" : "Usa un tema claro en toda la aplicación")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Toggle("Modo oscuro", isOn: Binding(
                get: { appearance == "dark" },
                set: { appearance = $0 ? "dark" : "light" }
            ))
            .labelsHidden()
            .tint(Color.brand)
        }
        .padding(16)
        .background(cardBackground)
    }

    private var textSizeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tamaño de texto")
                    .font(.subheadline.weight(.semibold))
                Text("Ajusta el tamaño de fuente para una mejor lectura")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                sizeChoice("Pequeño", value: "small", font: .subheadline)
                sizeChoice("Normal", value: "normal", font: .title3)
                sizeChoice("Grande", value: "large", font: .title)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Idioma")
                    .font(.subheadline.weight(.semibold))
                Text("Guarda tu idioma preferido")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                languageChoice("Español", value: "es")
                languageChoice("English", value: "en")
            }

            Text("La traducción de la interfaz estará disponible más adelante.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(cardBackground)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(Color.brand)
            .padding(.leading, 4)
    }

    private func sizeChoice(_ title: String, value: String, font: Font) -> some View {
        let selected = textSize == value
        return Button { textSize = value } label: {
            VStack(spacing: 6) {
                Text("Aa")
                    .font(font.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? Color.brand : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Color.brand.opacity(0.1) : Color.cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.brand : Color.primary.opacity(0.14), lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityValue(selected ? "Seleccionado" : "No seleccionado")
    }

    private func languageChoice(_ title: String, value: String) -> some View {
        let selected = language == value
        return Button { language = value } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Color.onBrand : Color.primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Color.brand : Color.cardBackground))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.brand : Color.primary.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityValue(selected ? "Seleccionado" : "No seleccionado")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.cardBackground)
            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}
