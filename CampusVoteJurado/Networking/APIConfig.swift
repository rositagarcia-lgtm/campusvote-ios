import Foundation

/// Dirección del backend. Se cambia aquí y en ningún otro lado.
enum APIConfig {
    /// Backend publicado en Render (HTTPS). Confirmar el nombre del servicio en el panel de Render.
    /// Para el simulador contra el backend local: "https://campusvote-api-iwpm.onrender.com"
    /// (requiere NSAllowsLocalNetworking en el Info.plist).
    static let baseURL: URL = {
        guard let url = URL(string: "https://campusvote-api-iwpm.onrender.com/api") else {
            preconditionFailure("La URL base del backend no es válida")
        }
        return url
    }()
}
