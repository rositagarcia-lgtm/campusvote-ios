import SwiftUI

struct JuryNotice: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let message: String
    let isRead: Bool
    let type: String
    let createdAt: Date?
    let event: String?

    enum CodingKeys: String, CodingKey {
        case id, title, message, type, metadata
        case isRead = "is_read"
        case createdAt = "created_at"
    }

    func markedRead() -> JuryNotice {
        JuryNotice(id: id, title: title, message: message, isRead: true, type: type, createdAt: createdAt, event: event)
    }

    init(id: String, title: String, message: String, isRead: Bool, type: String, createdAt: Date?, event: String?) {
        self.id = id
        self.title = title
        self.message = message
        self.isRead = isRead
        self.type = type
        self.createdAt = createdAt
        self.event = event
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Aviso"
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "SYSTEM_ALERT"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        event = try container.decodeIfPresent(NoticeMetadata.self, forKey: .metadata)?.event
    }
}

private struct NoticeMetadata: Decodable {
    let event: String?
}

private struct UnreadPayload: Decodable {
    let unreadCount: Int
    enum CodingKeys: String, CodingKey { case unreadCount = "unread_count" }
}

private struct ReadFlag: Encodable {
    let isRead: Bool
    enum CodingKeys: String, CodingKey { case isRead = "is_read" }
}

@MainActor
@Observable
final class NoticesStore {
    var items: [JuryNotice] = []
    var unread = 0
    var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load() async {
        isLoading = items.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let page = api.sendPage(
                Endpoint(path: "notifications", method: "GET", queryItems: [
                    URLQueryItem(name: "limit", value: "30")
                ]),
                as: JuryNotice.self
            )
            async let count = api.send(
                Endpoint(path: "notifications/unread-count", method: "GET"),
                as: UnreadPayload.self
            )
            items = try await page.items
            unread = try await count.unreadCount
        } catch {
            errorMessage = error.userMessage
        }
    }

    func markAllRead() async {
        do {
            try await api.send(Endpoint(path: "notifications/mark-all-read", method: "PATCH"))
            unread = 0
            items = items.map { $0.markedRead() }
        } catch {
            errorMessage = error.userMessage
        }
    }

    func reset() {
        items = []
        unread = 0
        errorMessage = nil
    }
}

struct HeaderBell: View {
    @Environment(NoticesStore.self) private var notices

    var body: some View {
        NavigationLink {
            NoticesView()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                if notices.unread > 0 {
                    Text(notices.unread > 9 ? "9+" : "\(notices.unread)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.onBrand)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.brand))
                        .offset(x: 8, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Avisos")
        .task { await notices.load() }
    }
}

struct NoticesView: View {
    @Environment(\.locale) private var locale
    @Environment(NoticesStore.self) private var notices
    @Environment(SessionStore.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if notices.isLoading && notices.items.isEmpty {
                    ProgressView("Cargando avisos...")
                        .frame(maxWidth: .infinity, minHeight: 180)
                } else if let message = notices.errorMessage, notices.items.isEmpty {
                    ScreenStateView(
                        icon: "wifi.exclamationmark",
                        title: "No pudimos cargar los avisos",
                        message: message,
                        actionTitle: "Reintentar"
                    ) { Task { await notices.load() } }
                } else if notices.items.isEmpty {
                    ScreenStateView(
                        icon: "bell",
                        title: "Estás al día",
                        message: "Aquí verás los avisos de tus ferias."
                    )
                } else {
                    if notices.unread > 0 {
                        Button("Marcar leídas") { Task { await notices.markAllRead() } }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brand)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    ForEach(Array(NoticeGroups.sections(notices.items).enumerated()), id: \.offset) { _, section in
                        NoticeDayHeader(label: section.label, count: section.items.count)
                        ForEach(section.items) { item in
                            NoticeCard(notice: item)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(L10n.tr("Avisos", locale: locale))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            async let brand: Void = session.refreshBrand()
            async let list: Void = notices.load()
            _ = await (brand, list)
        }
        .task { await notices.load() }
    }
}
