import Foundation

struct FairAssignment: Decodable, Identifiable, Hashable {
    var id: String { fair.id }
    let fair: Fair

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
    let startsAt: String?
    let endsAt: String?
    let organizationId: String?
    let organizationName: String?
    let siteId: String?
    let siteName: String?

    var isOpen: Bool { status.uppercased() == "OPEN" }

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
        case id, name, description, status, organization, site
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case organizationId = "organization_id"
        case organizationName = "organization_name"
        case siteId = "site_id"
        case siteName = "site_name"
        case fair
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
        startsAt = try container.decodeIfPresent(String.self, forKey: .startsAt)
        endsAt = try container.decodeIfPresent(String.self, forKey: .endsAt)

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

    static func == (lhs: Fair, rhs: Fair) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

typealias AssignedFair = Fair
