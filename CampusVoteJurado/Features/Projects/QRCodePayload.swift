import Foundation

/// Datos mínimos que puede traer el QR de un stand.
/// Acepta JSON, URLs con UUIDs o el UUID del proyecto solamente.
struct QRCodePayload: Hashable {
    let fairId: String?
    let projectId: String

    static func parse(_ raw: String) -> QRCodePayload? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if let fromJSON = parseJSON(text) {
            return fromJSON
        }

        let ids = uuids(in: text)
        if ids.count >= 2 {
            return QRCodePayload(fairId: ids[0], projectId: ids[1])
        }
        if ids.count == 1 {
            return QRCodePayload(fairId: nil, projectId: ids[0])
        }
        return nil
    }

    private static func parseJSON(_ text: String) -> QRCodePayload? {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let json = object as? [String: Any] else {
            return nil
        }

        let fair = (json["fair_id"] as? String)
            ?? (json["fairId"] as? String)
            ?? nestedId(json["fair"])
        let project = (json["project_id"] as? String)
            ?? (json["projectId"] as? String)
            ?? (json["project"] as? String)
            ?? nestedId(json["project"])

        guard let project else { return nil }
        return QRCodePayload(fairId: fair, projectId: project)
    }

    private static func nestedId(_ value: Any?) -> String? {
        guard let object = value as? [String: Any] else { return value as? String }
        return (object["id"] as? String) ?? (object["project_id"] as? String)
    }

    private static func uuids(in text: String) -> [String] {
        let pattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let matchRange = Range(match.range, in: text) else { return nil }
            return String(text[matchRange])
        }
    }
}
