import SwiftUI

struct SignedInExperience: View {
    let user: User
    @AppStorage private var hasSeenOnboarding: Bool

    init(user: User) {
        self.user = user
        _hasSeenOnboarding = AppStorage(wrappedValue: false, "campusvote.onboarding.v1.\(user.id)")
    }

    var body: some View {
        if hasSeenOnboarding {
            MainTabView()
        } else {
            JuryOnboardingView { hasSeenOnboarding = true }
        }
    }
}

struct JuryOnboardingView: View {
    let onFinish: () -> Void
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @AccessibilityFocusState private var focusedPage: Int?

    private let pages: [(icon: String, title: String, message: String)] = [
        ("rectangle.grid.2x2", "Tu panel de jurado",
         "Aquí ves las ferias y los proyectos que te asignaron."),
        ("star.bubble", "Reseñas que ayudan",
         "Califica con estrellas y deja un comentario concreto y respetuoso que ayude al equipo a mejorar."),
        ("person.crop.circle.badge.checkmark", "Quién ve tu comentario",
         "El equipo ve tus estrellas, comentario y fecha sin tu nombre. Otros jurados pueden leer reseñas anónimas tras publicarse los resultados. Los administradores sí ven tu nombre.")
    ]

    var body: some View {
        VStack(spacing: AppSpacing.section) {
            OrganizationHeader(title: "Panel de jurado")
            HStack {
                Text(L10n.format("Paso %d de 3", locale: locale, page + 1))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Saltar", action: onFinish)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, AppSpacing.screen)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    ScrollView {
                        VStack(spacing: AppSpacing.large) {
                            Image(systemName: pages[index].icon)
                                .font(.largeTitle)
                                .foregroundStyle(Color.brandTeal)
                                .accessibilityHidden(true)
                            Text(L10n.tr(pages[index].title, locale: locale))
                                .font(.title.weight(.bold))
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityFocused($focusedPage, equals: index)
                            Text(L10n.tr(pages[index].message, locale: locale))
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(AppSpacing.large)
                        .frame(maxWidth: .infinity)
                        .premiumSurface()
                        .padding(AppSpacing.screen)
                        .padding(.bottom, 40)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            Button {
                if page == pages.count - 1 { onFinish() }
                else { withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 } }
            } label: {
                Text(L10n.tr(page == pages.count - 1 ? "Empezar" : "Siguiente", locale: locale))
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Color.onBrand)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.bottom, AppSpacing.section)
        }
        .tint(Color.brand)
        .background(Color.appBackground.ignoresSafeArea())
        .onChange(of: page) { _, index in focusedPage = index }
    }
}
