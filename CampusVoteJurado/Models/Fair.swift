import Foundation

struct FairAssignment: Decodable, Identifiable, Hashable {
    var id: String { fair.id }
    let fair: Fair
    let access: ReviewAccess

    enum CodingKeys: String, CodingKey { case fair }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if values.contains(.fair) {
            fair = try values.decode(Fair.self, forKey: .fair)
        } else {
            fair = try Fair(from: decoder)
        }
        access = (try? ReviewAccess(from: decoder))?.merging(fair.access)
            .resolved(status: fair.status, startsAt: fair.startsAt)
            ?? fair.access.resolved(status: fair.status, startsAt: fair.startsAt)
    }

    static func == (lhs: FairAssignment, rhs: FairAssignment) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FairOrganization: Decodable, Hashable {
    let id: String
    let name: String
}

struct FairSite: Decodable, Hashable {
    let id: String
    let name: String
    let city: String?
}

struct Fair: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let status: String
    let access: ReviewAccess
    let startsAt: String?
    let endsAt: String?
    let organizationId: String?
    let organizationName: String?
    let siteId: String?
    let siteName: String?
    let imageUrl: String?

    var isOpen: Bool { FairPhase.parse(status) == .live }

    var coverURL: URL? {
        guard let imageUrl else { return nil }
        let trimmed = imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let absolute = URL(string: trimmed),
           let scheme = absolute.scheme?.lowercased(),
           scheme == "https" || scheme == "http" {
            return absolute
        }
        let origin = APIConfig.baseURL.deletingLastPathComponent()
        let relative = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        return URL(string: relative, relativeTo: origin)?.absoluteURL
    }

    var organization: FairOrganization? {
        guard let organizationName, !organizationName.isEmpty else { return nil }
        return FairOrganization(id: organizationId ?? organizationName, name: organizationName)
    }

    var site: FairSite? {
        guard let siteName, !siteName.isEmpty else { return nil }
        return FairSite(id: siteId ?? siteName, name: siteName, city: nil)
    }

    var heading: String {
        if let siteName, !siteName.isEmpty, let organizationName, !organizationName.isEmpty {
            return "\(organizationName) · \(siteName)"
        }
        return organizationName ?? siteName ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, summary, status, organization, site, image
        case shortDescription = "short_description"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case organizationId = "organization_id"
        case organizationName = "organization_name"
        case siteId = "site_id"
        case siteName = "site_name"
        case fair
        case coverUrl = "cover_url"
        case bannerUrl = "banner_url"
        case imageUrl = "image_url"
        case photoUrl = "photo_url"
        case logoUrl = "logo_url"
        case imageUrls = "image_urls"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if !container.contains(.id), container.contains(.fair) {
            self = try container.decode(Fair.self, forKey: .fair)
            return
        }
        id = Self.flexibleID(container, key: .id) ?? UUID().uuidString
        name = Self.flexibleText(container, keys: [.name]) ?? "Feria"
        description = Self.flexibleText(container, keys: [.description, .summary, .shortDescription])
        status = Self.flexibleText(container, keys: [.status]) ?? ""
        access = (try? ReviewAccess(from: decoder)) ?? ReviewAccess()
        startsAt = Self.flexibleText(container, keys: [.startsAt])
        endsAt = Self.flexibleText(container, keys: [.endsAt])
        imageUrl = Self.firstImage(in: container)

        var orgId = Self.flexibleID(container, key: .organizationId)
        var orgName = Self.flexibleText(container, keys: [.organizationName])
        if let nested = Self.looseRef(container, key: .organization) {
            orgId = orgId ?? nested.id
            orgName = orgName ?? nested.name
        } else if let plain = Self.flexibleText(container, keys: [.organization]) {
            orgName = orgName ?? plain
        }
        organizationId = orgId
        organizationName = orgName

        var parsedSiteId = Self.flexibleID(container, key: .siteId)
        var parsedSiteName = Self.flexibleText(container, keys: [.siteName])
        if let nested = Self.looseRef(container, key: .site) {
            parsedSiteId = parsedSiteId ?? nested.id
            parsedSiteName = parsedSiteName ?? nested.name ?? nested.city
        } else if let plain = Self.flexibleText(container, keys: [.site]) {
            parsedSiteName = parsedSiteName ?? plain
        }
        siteId = parsedSiteId
        siteName = parsedSiteName
    }

    private struct LooseRef: Decodable {
        let id: String?
        let name: String?
        let city: String?
        let url: String?

        enum CodingKeys: String, CodingKey {
            case id, name, city, url, src, path
            case coverUrl = "cover_url"
            case imageUrl = "image_url"
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            if let text = try? values.decodeIfPresent(String.self, forKey: .id) {
                id = text
            } else if let number = try? values.decodeIfPresent(Int.self, forKey: .id) {
                id = String(number)
            } else {
                id = nil
            }
            name = try? values.decodeIfPresent(String.self, forKey: .name)
            city = try? values.decodeIfPresent(String.self, forKey: .city)
            url = Self.first(values, keys: [.url, .src, .path, .coverUrl, .imageUrl])
        }

        private static func first(
            _ values: KeyedDecodingContainer<CodingKeys>,
            keys: [CodingKeys]
        ) -> String? {
            for key in keys {
                if let text = try? values.decodeIfPresent(String.self, forKey: key) {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { return trimmed }
                }
            }
            return nil
        }
    }

    private static func looseRef(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> LooseRef? {
        try? container.decode(LooseRef.self, forKey: key)
    }

    private static func flexibleText(
        _ container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> String? {
        for key in keys {
            if let text = try? container.decodeIfPresent(String.self, forKey: key) {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return nil
    }

    private static func flexibleID(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> String? {
        if let text = flexibleText(container, keys: [key]) { return text }
        if let number = try? container.decodeIfPresent(Int.self, forKey: key) { return String(number) }
        return nil
    }

    private static func firstImage(in container: KeyedDecodingContainer<CodingKeys>) -> String? {
        let keys: [CodingKeys] = [.coverUrl, .bannerUrl, .imageUrl, .photoUrl, .image, .logoUrl]
        for key in keys {
            if let text = flexibleText(container, keys: [key]) { return text }
            if let nested = looseRef(container, key: key)?.url { return nested }
        }
        if let urls = try? container.decodeIfPresent([String].self, forKey: .imageUrls) {
            return urls.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        return nil
    }

    static func == (lhs: Fair, rhs: Fair) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

typealias AssignedFair = Fair
