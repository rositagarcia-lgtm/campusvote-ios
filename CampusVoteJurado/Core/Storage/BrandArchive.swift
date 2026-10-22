import Foundation

enum BrandArchive {
    private static func key(user: User) -> String {
        "campusvote.brand.\(user.id).\(user.organizationId ?? "none")"
    }

    static func load(user: User) -> OrganizationBrand? {
        guard let data = UserDefaults.standard.data(forKey: key(user: user)) else { return nil }
        return try? JSONDecoder().decode(OrganizationBrand.self, from: data)
    }

    static func save(_ brand: OrganizationBrand, user: User) {
        guard let data = try? JSONEncoder().encode(brand) else { return }
        UserDefaults.standard.set(data, forKey: key(user: user))
    }

    static func clear(user: User) {
        UserDefaults.standard.removeObject(forKey: key(user: user))
    }
}

extension OrganizationBrand: Encodable {
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encodeIfPresent(logo, forKey: .logo)
        try values.encodeIfPresent(primaryColor, forKey: .primaryColorSnake)
        try values.encodeIfPresent(secondaryColor, forKey: .secondaryColorSnake)
        try values.encodeIfPresent(orgType, forKey: .orgType)
    }
}
