import Foundation

enum APITransport {
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 45
        configuration.waitsForConnectivity = false
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

    static func throwNormalized(_ error: Error) throws -> Never {
        if error is CancellationError {
            throw CancellationError()
        }
        if let urlError = error as? URLError, urlError.code == .cancelled {
            throw CancellationError()
        }
        throw APIError.network
    }
}
