import SwiftUI

struct FairListView: View {
    @Environment(FairsStore.self) private var fairsStore
    @Environment(SessionStore.self) private var session
    @State private var path: [String] = []

    private var institutionName: String {
        if let name = InstitutionAppearance.name, !name.isEmpty { return name }
        return fairsStore.organizationName ?? "Institución"
    }

    private var greetingName: String {
        guard case .signedIn(let user) = session.phase else { return "" }
        let first = user.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = user.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !last.isEmpty, first.localizedCaseInsensitiveContains(last) {
            return first
        }
        return user.fullName
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let errorMessage = fairsStore.errorMessage {
                            ErrorBanner(message: errorMessage)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield")
                                    .font(.caption2)
                                Text("JURADO CALIFICADOR")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(.secondary)

                            Text("Bienvenido, \(greetingName)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }

                        seccionAbiertas

                        if !fairsStore.closedFairs.isEmpty {
                            seccionCerradas
                        }
                    }
                    .padding(18)
                }
                .refreshable {
                    await fairsStore.fetchMyAssignments()
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { fairId in
                ProjectListView(fairId: fairId)
            }
            .task {
                await fairsStore.fetchMyAssignments()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                logo

                VStack(alignment: .leading, spacing: 2) {
                    Text(institutionName)
                        .font(.headline)
                        .foregroundStyle(Color.onBrand)
                        .lineLimit(1)
                    if let kind = InstitutionAppearance.kindLabel, !kind.isEmpty {
                        Text(kind)
                            .font(.subheadline)
                            .foregroundStyle(Color.onBrand.opacity(0.85))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 16)

            Rectangle()
                .fill(Color.onBrand.opacity(0.35))
                .frame(height: 0.5)
        }
        .background {
            Color.brand
                .ignoresSafeArea(edges: .top)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 160, height: 160)
                        .offset(x: 48, y: -36)
                }
        }
    }

    private var logo: some View {
        Group {
            if let url = InstitutionAppearance.logoURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Color.white.opacity(0.16)
                    }
                }
            } else {
                Image(systemName: "building.columns")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)
            }
        }
        .padding(8)
        .frame(width: 52, height: 52)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.95)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var seccionAbiertas: some View {
        VStack(alignment: .leading, spacing: 10) {
            encabezado(titulo: "ABIERTAS", derecha: "\(fairsStore.activeFairs.count)")

            if fairsStore.isLoading && fairsStore.activeFairs.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if fairsStore.activeFairs.isEmpty {
                vacioAbiertas
            } else {
                ForEach(fairsStore.activeFairs) { assignment in
                    Button {
                        path.append(assignment.fair.id)
                    } label: {
                        FilaDeFeria(fair: assignment.fair, opens: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var vacioAbiertas: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.columns")
                .font(.title2)
                .foregroundStyle(Color.brand)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Color.brand.opacity(0.12)))

            Text("No hay ferias abiertas")
                .font(.subheadline.weight(.semibold))

            Text("Cuando tu institución abra una feria asignada, aparecerá aquí.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private var seccionCerradas: some View {
        VStack(alignment: .leading, spacing: 10) {
            encabezado(titulo: "CERRADAS", derecha: "\(fairsStore.closedFairs.count)")

            ForEach(fairsStore.closedFairs) { assignment in
                FilaDeFeria(fair: assignment.fair, opens: false)
            }
        }
    }

    private func encabezado(titulo: String, derecha: String) -> some View {
        HStack {
            Text(titulo)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(derecha)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FilaDeFeria: View {
    let fair: Fair
    let opens: Bool

    private var estado: (texto: String, color: Color) {
        switch fair.status.uppercased() {
        case "OPEN":
            return ("Abierta", Color.brand)
        case "CLOSED":
            return ("Cerrada", .secondary)
        default:
            return ("Programada", Color.brandGold)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(fair.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if let site = fair.siteName, !site.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.caption2)
                        Text(site)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text(estado.texto)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(estado.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(estado.color.opacity(0.12)))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }
}
