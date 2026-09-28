import SwiftUI
import UIKit

/// Detalle de un proyecto para revisión del jurado (GET /fairs/:id/projects/:projectId).
struct ProjectDetailView: View {
    let fairId: String
    let projectId: String

    @State private var detail: ProjectDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let api = APIClient.shared
    private let tealDark = Color(red: 0.03, green: 0.32, blue: 0.28)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

                if isLoading {
                    ProgressView("Cargando proyecto...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let detail {
                    header(detail)

                    if let description = detail.description, !description.isEmpty {
                        section("DESCRIPCIÓN") {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }

                    ProjectVotePanel(fairId: fairId, projectId: projectId)

                    if !detail.imageUrls.isEmpty || detail.coverUrl != nil || detail.logoUrl != nil {
                        section("FOTOS") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(gallery(detail), id: \.self) { url in
                                        CoverImage(url: URL(string: url))
                                            .frame(width: 140, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                    }

                    if let video = detail.videoUrl, let url = URL(string: video) {
                        Link(destination: url) {
                            Label("Ver video", systemImage: "play.rectangle")
                                .font(.subheadline).bold()
                        }
                    }

                    if let urlString = detail.projectUrl, let url = URL(string: urlString) {
                        Link(destination: url) {
                            Label("Abrir URL del proyecto", systemImage: "link")
                                .font(.subheadline).bold()
                                .foregroundColor(tealDark)
                        }
                    }

                    if !detail.activeCriteria.isEmpty {
                        section("CRITERIOS") {
                            ForEach(detail.activeCriteria) { criterion in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(criterion.name).font(.subheadline.bold())
                                    if let description = criterion.description, !description.isEmpty {
                                        Text(description).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    if !detail.members.isEmpty {
                        section("INTEGRANTES") {
                            ForEach(detail.members) { member in
                                HStack(spacing: 12) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(member.firstName ?? "") \(member.lastName ?? "")")
                                            .font(.subheadline)
                                        Text(member.role ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Proyecto")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func header(_ detail: ProjectDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.name)
                .font(.title2).bold()
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                if let stand = detail.standCode {
                    Label(stand, systemImage: "shippingbox.fill")
                        .font(.caption).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
                if let category = detail.categoryName {
                    Text(category)
                        .font(.caption).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tealDark.opacity(0.1))
                        .foregroundColor(tealDark)
                        .cornerRadius(6)
                }
            }

            if let status = detail.status {
                Text("Estado: \(status)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption).bold()
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(14)
        }
    }

    private func gallery(_ detail: ProjectDetail) -> [String] {
        var urls: [String] = []
        if let cover = detail.coverUrl { urls.append(cover) }
        if let logo = detail.logoUrl { urls.append(logo) }
        urls.append(contentsOf: detail.imageUrls)
        return urls
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await api.send(Endpoint.projectDetail(fairId: fairId, projectId: projectId), as: ProjectDetail.self)
        } catch {
            errorMessage = error.userMessage
        }
    }
}

/// Un voto por jurado en toda la feria. No muestra cuál proyecto eligió.
struct ProjectVotePanel: View {
    let fairId: String
    let projectId: String

    @Environment(FairsStore.self) private var fairs
    @State private var hasVoted = false
    @State private var receipt: String?
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var confirm = false

    private var fairIsReady: Bool {
        guard let fair = (fairs.activeFairs + fairs.closedFairs).first(where: { $0.fair.id == fairId })?.fair else {
            return true
        }
        guard fair.isOpen else { return false }
        guard let startsAt = fair.startsAt else { return true }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        guard let date = parser.date(from: startsAt) ?? plain.date(from: startsAt) else { return true }
        return date <= Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if hasVoted {
                Label("Tu voto en esta feria ya fue emitido.", systemImage: "checkmark.seal")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
            } else if fairIsReady {
                Button("Elegir como mi voto") { confirm = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(isWorking)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await loadStatus() }
        .confirmationDialog(
            "Este voto es uno solo para toda la feria.",
            isPresented: $confirm,
            titleVisibility: .visible
        ) {
            Button("Emitir voto") { Task { await cast() } }
            Button("Cancelar", role: .cancel) {}
        }
        .alert("Comprobante", isPresented: Binding(
            get: { receipt != nil },
            set: { if !$0 { receipt = nil } }
        )) {
            Button("Copiar") {
                if let receipt {
                    UIPasteboard.general.string = receipt
                }
            }
            Button("Listo", role: .cancel) {}
        } message: {
            Text("Guárdalo ahora: \(receipt ?? ""). No se vuelve a mostrar.")
        }
    }

    private func loadStatus() async {
        guard let status = try? await APIClient.shared.send(
            .votingStatus(fairId: fairId),
            as: VotingStatus.self
        ) else { return }
        hasVoted = status.hasVoted
    }

    private func cast() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let result = try await APIClient.shared.send(
                .castVote(fairId: fairId, projectId: projectId),
                as: VoteReceipt.self
            )
            receipt = result.receiptCode
            hasVoted = true
        } catch {
            errorMessage = error.userMessage
        }
    }
}