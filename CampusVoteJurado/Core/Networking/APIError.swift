import Foundation

/// Errores de la API, cada uno con un mensaje listo para mostrar.
enum APIError: Error, Equatable {
    /// El backend respondió con error: { success: false, error: { code, message } }.
    case server(status: Int, code: String, message: String)
    /// La sesión venció y no se pudo renovar: hay que volver a iniciar sesión.
    case sessionExpired
    /// Sin conexión, o el servidor no respondió.
    case network
    /// La respuesta no tiene el formato esperado.
    case decoding(String)
    /// El dispositivo no permitió guardar los tokens en el Keychain.
    case secureStorage

    var message: String {
        switch self {
        case .server(_, _, let message):
            // El backend ya manda el mensaje en español, listo para mostrar.
            return message
        case .sessionExpired:
            return "Tu sesión venció. Vuelve a iniciar sesión."
        case .network:
            return "No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo."
        case .decoding:
            return "El servidor respondió algo inesperado. Avísale al equipo."
        case .secureStorage:
            return "No se pudo guardar la sesión de forma segura. Cierra y vuelve a abrir la aplicación."
        }
    }

    /// Código del backend (CONFLICT, FORBIDDEN, ACCOUNT_LOCKED…), si lo hay.
    var code: String? {
        if case .server(_, let code, _) = self {
            return code
        }
        return nil
    }

    /// El servidor rechazó la sesión (token inválido, cuenta suspendida, etc.).
    /// Un fallo de red o un 5xx NO debe cerrar la sesión.
    var isSessionRejection: Bool {
        switch self {
        case .sessionExpired:
            return true
        case .server(let status, _, _):
            return status == 401 || status == 403
        default:
            return false
        }
    }

    /// Fallo transitorio: conviene conservar los tokens y reintentar.
    var isTransient: Bool {
        switch self {
        case .network:
            return true
        case .server(let status, _, _):
            return status == 429 || status >= 500
        case .sessionExpired, .decoding, .secureStorage:
            return false
        }
    }
}

/// Forma del cuerpo de error del backend.
struct ServerErrorBody: Decodable {
    struct Detail: Decodable {
        let code: String
        let message: String
    }

    let error: Detail
}

extension Error {
    /// Mensaje para la interfaz, o nil si la tarea solo se canceló
    /// (por ejemplo, al salir de la pantalla antes de que llegue la respuesta).
    var userMessage: String? {
        if self is CancellationError
            || (self as? URLError)?.code == .cancelled {
            return nil
        }
        if let apiError = self as? APIError {
            return apiError.message
        }
        return "Ocurrió un error inesperado."
    }
}
