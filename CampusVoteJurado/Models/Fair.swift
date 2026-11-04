import Foundation

struct FairAssignment: Decodable, Identifiable, Hashable {
    var id: String { fair.id }
    let fair: Fair
    let access: ReviewAccess

    enum CodingKeys: String, CodingKey { case fair }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fair = try values.decode(Fair.self, forKey: .fair)
        access = try ReviewAccess(from: decoder).merging(fair.access)
            .resolved(status: fair.status, startsAt: fair.startsAt)
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

    var isOpen: Bool { status.uppercased() == "OPEN" }

    var coverURL: URL? {
        guard let imageUrl,
              let url = URL(string: imageUrl),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else { return nil }
        return url
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
        case id, name, description, status, organization, site, image
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if !container.contains(.id), container.contains(.fair) {
            self = try container.decode(Fair.self, forKey: .fair)
            return
        }
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Feria"
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        access = try ReviewAccess(from: decoder)
        startsAt = try container.decodeIfPresent(String.self, forKey: .startsAt)
        endsAt = try container.decodeIfPresent(String.self, forKey: .endsAt)
        imageUrl = Self.firstImage(in: container)

        var orgId = try container.decodeIfPresent(String.self, forKey: .organizationId)
        var orgName = try container.decodeIfPresent(String.self, forKey: .organizationName)
        if let nested = try container.decodeIfPresent(FairOrganization.self, forKey: .organization) {
            orgId = orgId ?? nested.id
            orgName = orgName ?? nested.name
        }
        organizationId = orgId
        organizationName = orgName

        var parsedSiteId = try container.decodeIfPresent(String.self, forKey: .siteId)
        var parsedSiteName = try container.decodeIfPresent(String.self, forKey: .siteName)
        if let nested = try container.decodeIfPresent(FairSite.self, forKey: .site) {
            parsedSiteId = parsedSiteId ?? nested.id
            parsedSiteName = parsedSiteName ?? nested.name
        }
        siteId = parsedSiteId
        siteName = parsedSiteName
    }

    private static func firstImage(in container: KeyedDecodingContainer<CodingKeys>) -> String? {
        let keys: [CodingKeys] = [.coverUrl, .bannerUrl, .imageUrl, .photoUrl, .image, .logoUrl]
        for key in keys {
            guard let value = try? container.decodeIfPresent(String.self, forKey: key) else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    static func == (lhs: Fair, rhs: Fair) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

typealias AssignedFair = Fair
