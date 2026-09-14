import Foundation

/// Cada ruta del backend que usa la app. El detalle de cada una está en el
/// documento "Contrato API del Jurado".
enum Endpoint {
    // Sesión
    case login(email: String, password: String)
    case verifyTotp(code: String, tempToken: String)
    case refresh(refreshToken: String)
    case me
    case logout(refreshToken: String?)

    // Ferias y declaración
    case myAssignments
    case declaration(fairId: String)
    case signDeclaration(fairId: String, statement: String)

    // Proyectos
    case categories(fairId: String)
    case stands(fairId: String)
    case projects(fairId: String, search: String?, categoryId: String?, standId: String?)
    case projectDetail(fairId: String, projectId: String)

    // Evaluación
    case rubric(fairId: String)
    case createEvaluation(fairId: String, input: EvaluationInput)
    case updateEvaluation(fairId: String, evaluationId: String, input: EvaluationInput)
    case myProgress(fairId: String)

    var method: String {
        switch self {
        case .login, .verifyTotp, .refresh, .logout, .signDeclaration, .createEvaluation:
            return "POST"
        case .updateEvaluation:
            return "PUT"
        default:
            return "GET"
        }
    }

    var path: String {
        switch self {
        case .login: return "auth/login"
        case .verifyTotp: return "auth/totp/login-verify"
        case .refresh: return "auth/refresh"
        case .me: return "auth/me"
        case .logout: return "auth/logout"
        case .myAssignments: return "fairs/my-assignments"
        case .declaration(let fairId), .signDeclaration(let fairId, _):
            return "fairs/\(fairId)/jury/declaration"
        case .categories(let fairId): return "fairs/\(fairId)/categories"
        case .stands(let fairId): return "fairs/\(fairId)/stands"
        case .projects(let fairId, _, _, _): return "fairs/\(fairId)/projects"
        case .projectDetail(let fairId, let projectId): return "fairs/\(fairId)/projects/\(projectId)"
        case .rubric(let fairId): return "fairs/\(fairId)/rubric"
        case .createEvaluation(let fairId, _): return "fairs/\(fairId)/evaluations"
        case .updateEvaluation(let fairId, let evaluationId, _):
            return "fairs/\(fairId)/evaluations/\(evaluationId)"
        case .myProgress(let fairId): return "fairs/my-progress/\(fairId)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .myAssignments:
            return [URLQueryItem(name: "limit", value: "100")]
        case .projects(_, let search, let categoryId, let standId):
            var items = [URLQueryItem(name: "limit", value: "100")]
            if let search, !search.isEmpty {
                items.append(URLQueryItem(name: "search", value: search))
            }
            if let categoryId {
                items.append(URLQueryItem(name: "category_id", value: categoryId))
            }
            if let standId {
                items.append(URLQueryItem(name: "stand_id", value: standId))
            }
            return items
        default:
            return []
        }
    }

    /// Cuerpo JSON de la petición, si lleva uno.
    var body: (any Encodable)? {
        switch self {
        case .login(let email, let password):
            return LoginBody(email: email, password: password)
        case .verifyTotp(let code, _):
            return CodeBody(code: code)
        case .refresh(let refreshToken):
            return RefreshBody(refreshToken: refreshToken)
        case .logout(let refreshToken):
            return refreshToken.map { RefreshBody(refreshToken: $0) }
        case .signDeclaration(_, let statement):
            return DeclarationBody(statement: statement)
        case .createEvaluation(_, let input):
            return input
        case .updateEvaluation(_, _, let input):
            // Al corregir, el backend no acepta project_id: solo notas y comentario.
            return EvaluationUpdateBody(scores: input.scores, comment: input.comment)
        default:
            return nil
        }
    }

    /// Las rutas de sesión no llevan el token guardado.
    var usesStoredToken: Bool {
        switch self {
        case .login, .verifyTotp, .refresh:
            return false
        default:
            return true
        }
    }

    /// El segundo paso del 2FA se autentica con el token temporal del login.
    var explicitToken: String? {
        if case .verifyTotp(_, let tempToken) = self {
            return tempToken
        }
        return nil
    }
}

// Cuerpos de las peticiones. Las claves van tal cual las espera el backend.

private struct LoginBody: Encodable {
    let email: String
    let password: String
}

private struct CodeBody: Encodable {
    let code: String
}

private struct RefreshBody: Encodable {
    let refreshToken: String
}

private struct DeclarationBody: Encodable {
    let statement: String
}

private struct EvaluationUpdateBody: Encodable {
    let scores: [ScoreInput]
    let comment: String?
}
