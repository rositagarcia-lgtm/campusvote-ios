import Foundation

enum JSONCoding {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)

            let withMillis = ISO8601DateFormatter()
            withMillis.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withMillis.date(from: text) {
                return date
            }

            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: text) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Fecha inválida: \(text)"
            )
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        JSONEncoder()
    }
}

struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        encodeFunc = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
