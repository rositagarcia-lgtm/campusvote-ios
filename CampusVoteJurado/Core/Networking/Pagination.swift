import Foundation

struct PageInfo: Decodable, Hashable {
    let page: Int
    let limit: Int
    let total: Int

    var totalPages: Int {
        guard limit > 0 else { return 0 }
        return Int(ceil(Double(total) / Double(limit)))
    }

    init(page: Int, limit: Int, total: Int) {
        self.page = page
        self.limit = limit
        self.total = total
    }
}

struct PageResult<Item> {
    let items: [Item]
    let pagination: PageInfo
}
