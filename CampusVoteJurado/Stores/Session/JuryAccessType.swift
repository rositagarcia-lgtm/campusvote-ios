import Foundation

enum JuryAccessType: String, CaseIterable, Identifiable {
    case external = "Externo"
    case internalStaff = "Interno"

    var id: Self { self }

    var subtitle: String {
        switch self {
        case .external:
            return "Ingresa con el correo y contraseña asignados a tu cuenta de jurado."
        case .internalStaff:
            return "Recibe un código en tu correo institucional para ingresar como docente."
        }
    }
}
