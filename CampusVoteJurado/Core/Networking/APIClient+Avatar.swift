import Foundation

private struct AvatarLink: Encodable {
    let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
    }
}

private struct AvatarEnvelope: Decodable {
    struct Payload: Decodable { let url: String }
    let success: Bool
    let message: String?
    let data: Payload?
}

extension APIClient {
    func uploadAvatar(jpeg: Data) async throws -> URL {
        let raw = try await postAvatar(jpeg, canRefresh: true)
        guard let absolute = Self.absoluteMediaURL(raw) else {
            throw APIError.decoding("El servidor no devolvió la URL de la imagen")
        }
        try await send(Endpoint(
            path: "users/me",
            method: "PUT",
            body: AvatarLink(avatarUrl: absolute.absoluteString)
        ))
        return absolute
    }

    private func postAvatar(_ jpeg: Data, canRefresh: Bool) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent("upload/avatar"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = KeychainStore.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        body.append(jpeg)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        request.httpBody = body

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            try APITransport.throwNormalized(error)
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.network }
        if http.statusCode == 401, canRefresh {
            switch await renewAfterUnauthorized() {
            case .refreshed:
                return try await postAvatar(jpeg, canRefresh: false)
            case .invalid:
                expireSession(matching: request.value(forHTTPHeaderField: "Authorization"))
                throw APIError.sessionExpired
            case .unavailable:
                throw APIError.network
            }
        }
        let envelope = try decodeEnvelope(AvatarEnvelope.self, from: data)
        guard (200...299).contains(http.statusCode), envelope.success, let url = envelope.data?.url, !url.isEmpty else {
            throw APIError.decoding(envelope.message ?? "No se pudo guardar la foto")
        }
        return url
    }

    static func absoluteMediaURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed),
           let scheme = url.scheme?.lowercased(),
           scheme == "https" || scheme == "http" {
            return url
        }
        let origin = APIConfig.baseURL.deletingLastPathComponent()
        let relative = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        return URL(string: relative, relativeTo: origin)?.absoluteURL
    }
}
