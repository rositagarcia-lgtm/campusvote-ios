import Foundation

/// Dirección del backend. Se cambia aquí y en ningún otro lado.
enum APIConfig {
    /// API del jurado. El login no pide la marca de la institución.
    static let baseURL: URL = {
        guard let url = URL(string: "https://campusvote-rg13.onrender.com/api") else {
            preconditionFailure("La URL base del backend no es válida")
        }
        return url
    }()
}
