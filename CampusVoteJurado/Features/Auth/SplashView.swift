import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var statusMessage = "Cargando ferias y proyectos asignados..."

    private let tealDark = Color(red: 0.03, green: 0.32, blue: 0.28)
    private let lightGreenBg = Color(red: 0.82, green: 0.95, blue: 0.88)
    private let textGreen = Color(red: 0.05, green: 0.45, blue: 0.30)

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                Spacer()

                // MARK: - Logo & Identificación de Rol
                VStack(spacing: 20) {
                    Image("logo_campusvote")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .scaleEffect(isAnimating ? 1.02 : 0.96)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    VStack(spacing: 8) {
                        // Badge Oficial de Jurado
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.caption)
                            Text("PANEL DE JURADO EVALUADOR")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(textGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(lightGreenBg)
                        .clipShape(Capsule())

                        Text("Sistema Oficial de Calificación y Rúbricas")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // MARK: - Indicador de Carga y Estado
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(tealDark)

                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // MARK: - Footer Institucional
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Entorno Seguro de Evaluación")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.secondary)

                    Text("Campusvote Dirección Académica · 2026")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SplashView()
}
