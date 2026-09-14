import SwiftUI

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

                    if let urlString = detail.projectUrl, let url = URL(string: urlString) {
                        Link(destination: url) {
                            Label("Abrir URL del proyecto", systemImage: "link")
                                .font(.subheadline).bold()
                                .foregroundColor(tealDark)
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