import Foundation

/// Traduce prosa escrita por personas. En español no se llama.
/// Primero el servidor; si no alcanza, el mismo servicio desde el teléfono.
@MainActor
enum ProseTranslator {
    private static var cache: [String: String] = [:]
    private static var pending: [String: Task<String, Never>] = [:]

    static func translate(_ text: String) async -> String {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if source.isEmpty { return text }
        if let hit = cache[source] { return hit }
        if let task = pending[source] { return await task.value }
        let task = Task { await fetch(source) }
        pending[source] = task
        let value = await task.value
        pending[source] = nil
        if value != source { cache[source] = value }
        return value
    }

    private static func fetch(_ text: String) async -> String {
        var result = ""
        for chunk in pieces(text) {
            result += await one(chunk)
        }
        return result
    }

    private static func one(_ text: String) async -> String {
        if let server = await server(text), useful(server, text) { return server }
        if let memory = await memory(text), useful(memory, text) { return memory }
        return text
    }

    private static func server(_ text: String) async -> String? {
        struct Payload: Decodable { let translations: [String] }
        guard let payload = try? await APIClient.shared.send(
            Endpoint.translate(texts: [text], target: "en"),
            as: Payload.self
        ) else { return nil }
        return payload.translations.first
    }

    private static func memory(_ text: String) async -> String? {
        if text.count <= 450 { return await memoryPiece(text) }
        var result = ""
        var start = text.startIndex
        while start < text.endIndex {
            let end = text.index(start, offsetBy: 450, limitedBy: text.endIndex) ?? text.endIndex
            guard let piece = await memoryPiece(String(text[start..<end])) else { return nil }
            result += piece
            start = end
        }
        return result
    }

    private static func memoryPiece(_ text: String) async -> String? {
        var parts = URLComponents(string: "https://api.mymemory.translated.net/get")
        parts?.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "es|en")
        ]
        guard let url = parts?.url else { return nil }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode ?? 500 < 400,
              let body = try? JSONDecoder().decode(MemoryBody.self, from: data) else { return nil }
        if let top = body.responseData?.translatedText, useful(top, text) { return top }
        let best = body.matches?
            .filter { useful($0.translation, text) }
            .max { ($0.match ?? 0) < ($1.match ?? 0) }
        return best?.translation ?? body.responseData?.translatedText
    }

    private static func useful(_ value: String?, _ source: String) -> Bool {
        guard let value else { return false }
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text.uppercased().hasPrefix("MYMEMORY WARNING") { return false }
        return text.lowercased() != source.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func pieces(_ text: String) -> [String] {
        let units = Array(text.utf16)
        if units.count <= 2000 { return [text] }
        var result: [String] = []
        var start = 0
        while start < units.count {
            let end = min(start + 2000, units.count)
            let slice = units[start..<end]
            result.append(String(decoding: slice, as: UTF16.self))
            start = end
        }
        return result.isEmpty ? [text] : result
    }
}

private struct MemoryBody: Decodable {
    struct DataBody: Decodable { let translatedText: String? }
    struct Match: Decodable {
        let translation: String?
        let match: Double?

        enum CodingKeys: String, CodingKey { case translation, match }

        init(from decoder: Decoder) throws {
            let box = try decoder.container(keyedBy: CodingKeys.self)
            translation = try box.decodeIfPresent(String.self, forKey: .translation)
            if let value = try? box.decodeIfPresent(Double.self, forKey: .match) {
                match = value
            } else if let value = try? box.decodeIfPresent(Int.self, forKey: .match) {
                match = Double(value)
            } else {
                match = nil
            }
        }
    }

    let responseData: DataBody?
    let matches: [Match]?
}
