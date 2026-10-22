import Foundation

extension APIClient {
    static func mapError(status: Int, data: Data) -> APIError {
        if let body = try? JSONCoding.makeDecoder().decode(ServerErrorBody.self, from: data) {
            return .server(status: status, code: body.error?.code ?? body.code ?? "HTTP_\(status)",
                           message: body.error?.message ?? body.message ?? fallbackMessage(status))
        }
        return .server(status: status, code: "HTTP_\(status)", message: fallbackMessage(status))
    }

    static func fallbackMessage(_ status: Int) -> String {
        switch status {
        case 401: return "No se pudo verificar tu acceso. Revisa tus datos e inténtalo de nuevo."
        case 403: return "No tienes permiso para acceder a este contenido."
        case 404: return "El contenido solicitado ya no está disponible."
        case 409: return "La operación no está disponible en el estado actual. Actualiza e inténtalo de nuevo."
        case 429: return "Has realizado muchos intentos. Espera unos minutos e inténtalo de nuevo."
        default: return "No se pudo completar la solicitud. Inténtalo de nuevo."
        }
    }
}
