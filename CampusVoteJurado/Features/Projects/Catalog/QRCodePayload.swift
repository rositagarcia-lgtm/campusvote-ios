import Foundation

/// Solo extrae identificadores. Nunca abre URLs ni consulta catálogos públicos.
struct QRCodePayload: Hashable {
    let fairId: String?
    let projectId: String

    static func parse(_ raw: String) -> QRCodePayload? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.utf8.count <= 8192 else { return nil }
        if text.hasPrefix("{") { return parseJSON(text) }

        if let url = URLComponents(string: text), url.scheme != nil || text.contains("?") {
            let parts = url.path.split(separator: "/").map(String.init)
            // QR del stand: https://…/ferias/{fairId}/proyectos/{projectId}
            let fairIndex = parts.firstIndex { $0 == "ferias" || $0 == "fairs" }
            let fair = fairIndex.flatMap { index in
                parts.indices.contains(index + 1) ? validID(parts[index + 1]) : nil
            }
            if let item = url.queryItems?.first(where: { ["project", "projectId"].contains($0.name) }) {
                guard let project = item.value.flatMap(validID) else { return nil }
                return QRCodePayload(fairId: fair, projectId: project)
            }
            guard let project = parts.reversed().compactMap(validID).first else { return nil }
            // Una URL de feria sin proyecto no es un QR de proyecto.
            guard parts.last != "projects", parts.last != "proyectos", project != fair else { return nil }
            return QRCodePayload(fairId: fair, projectId: project)
        }

        let tokens = text.components(separatedBy: CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "-")).inverted)
        guard let project = tokens.reversed().compactMap(validID).first else { return nil }
        return QRCodePayload(fairId: nil, projectId: project)
    }

    private static func validID(_ text: String) -> String? {
        if UUID(uuidString: text) != nil { return text }
        return !text.isEmpty && text.allSatisfy { $0.isASCII && $0.isNumber } ? text : nil
    }

    private static func parseJSON(_ text: String) -> QRCodePayload? {
        guard let data = text.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let project = identifier(json["project_id"] ?? json["projectId"] ?? json["project"]) else {
            return nil
        }
        let fair = identifier(json["fair_id"] ?? json["fairId"] ?? json["fair"])
        return QRCodePayload(fairId: fair, projectId: project)
    }

    private static func identifier(_ value: Any?) -> String? {
        if let text = value as? String { return validID(text) }
        if let number = value as? NSNumber { return validID(number.stringValue) }
        if let object = value as? [String: Any] { return identifier(object["id"] ?? object["project_id"]) }
        return nil
    }
}
