import SwiftUI

struct SplashView: View {
    @Environment(\.locale) private var locale
    @State private var isAnimating = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Fondo dinámico con degradado sutil basado en el color de marca
            LinearGradient(
                colors: [Color.appBackground, Color.campusGreen.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Logo & Identificación
                VStack(spacing: 24) {
                    Image("logo_campusvote")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1.0 : 0.85)
                        .blur(radius: showContent ? 0 : 10)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showContent)

                    VStack(spacing: 12) {
                        // Badge con color de marca dinámico
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("PANEL DE JURADO EVALUADOR")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.5)
                        }
                        .foregroundColor(Color.campusGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.campusGreen.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.campusGreen.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: showContent)

                        Text("Reseñas y comentarios de proyectos")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color.campusGreen.opacity(0.7))
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
                    }
                }

                Spacer()

                // MARK: - Indicador de Carga Premium
                VStack(spacing: 16) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.campusGreen.opacity(0.15))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.campusGreen, Color.campusTeal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: isAnimating ? geometry.size.width : 0, height: 4)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: isAnimating)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 40)

                    Text(L10n.tr("Cargando ferias y proyectos asignados...", locale: locale))
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color.appNeutral)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)
                }
                .padding(.bottom, 40)

                // MARK: - Footer Institucional
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Entorno Seguro de Evaluación")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.3)
                    }
                    .foregroundColor(Color.appNeutral)

                    Text("Campusvote Dirección Académica · 2026")
                        .font(.system(size: 10))
                        .foregroundColor(Color.appNeutral.opacity(0.7))
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
