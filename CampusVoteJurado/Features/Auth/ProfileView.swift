import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(FairsStore.self) private var fairsStore
    @State private var isLoggingOut = false

    private let tealDark = Color(red: 0.03, green: 0.32, blue: 0.28)
    private let tealLight = Color(red: 0.88, green: 0.96, blue: 0.93)
    private let lightGreenBg = Color(red: 0.82, green: 0.95, blue: 0.88)
    private let textGreen = Color(red: 0.05, green: 0.45, blue: 0.30)

    private var sede: String {
        let partes = [fairsStore.organizationName, fairsStore.siteName].compactMap { $0 }
        return partes.isEmpty ? "Sin sede asignada" : partes.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                VStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 86, height: 86)
                            .foregroundColor(.gray.opacity(0.3))
                            .background(Circle().fill(Color.white))
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundColor(tealDark)
                            .background(Circle().fill(Color.white))
                    }

                    if case .signedIn(let user) = session.phase {
                        VStack(spacing: 4) {
                            Text(user.fullName)
                                .font(.title3).bold()
                                .foregroundColor(.primary)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "shield.checkmark.fill")
                                .font(.caption)
                            Text("JURADO EVALUADOR OFICIAL")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(textGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(lightGreenBg)
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(tealDark)
                                .frame(width: 32, height: 32)
                                .background(tealLight)
                                .cornerRadius(8)

                            Text("Sede\nInstitucional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text(sede)
                            .font(.subheadline).bold()
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                    }

                    Divider()

                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(tealDark)
                                .frame(width: 32, height: 32)
                                .background(tealLight)
                                .cornerRadius(8)

                            Text("Rol\nAsignado")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text("Jurado Calificador")
                            .font(.subheadline).bold()
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("CREDENCIALES Y SEGURIDAD")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ProfileRowLink(
                            icon: "iphone.radiowaves.left.and.right",
                            iconBg: tealDark,
                            title: "Verificación en dos pasos"
                        ) {
                            Text("Activa")
                                .font(.caption).bold()
                                .foregroundColor(textGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(lightGreenBg)
                                .cornerRadius(6)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)

                    Text("Cuenta de jurado con verificación en dos pasos para entrar a la app.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("SOPORTE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ProfileRowLink(
                            icon: "headphones",
                            iconBg: Color.orange,
                            title: "Mesa electoral de soporte"
                        )
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }

                VStack(spacing: 8) {
                    Button(action: logout) {
                        HStack(spacing: 8) {
                            if isLoggingOut {
                                ProgressView()
                            } else {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                            Text("Cerrar sesión")
                                .font(.subheadline).bold()
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                    }
                    .disabled(isLoggingOut)

                    Text("Cierra sesión para proteger el acceso a la plataforma.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 4) {
                    Text("CampusVote v2.0.1 (Build 108)")
                        .font(.caption2).bold()
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)

                    Text("CampusVote · Sistema de evaluación")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if fairsStore.activeFairs.isEmpty && fairsStore.closedFairs.isEmpty {
                await fairsStore.fetchMyAssignments()
            }
        }
    }

    @MainActor
    private func logout() {
        isLoggingOut = true
        Task {
            await session.logout()
        }
    }
}

struct ProfileRowLink<Accessory: View>: View {
    let icon: String
    let iconBg: Color
    let title: String
    let accessory: Accessory?

    init(
        icon: String,
        iconBg: Color,
        title: String,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.icon = icon
        self.iconBg = iconBg
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(iconBg)
                    .cornerRadius(8)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                if let accessory {
                    accessory
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}
