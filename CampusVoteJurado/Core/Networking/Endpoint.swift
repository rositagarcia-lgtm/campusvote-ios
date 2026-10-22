import Foundation

private struct LoginPayload: Encodable {
    let email: String
    let password: String
}

private struct CodePayload: Encodable {
    let code: String
}

private struct EmailPayload: Encodable {
    let email: String
}

private struct RefreshPayload: Encodable {
    let refreshToken: String
}

private struct PasswordChangePayload: Encodable {
    let currentPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}

struct Endpoint {
    let path: String
    let method: String
    var queryItems: [URLQueryItem] = []
    var body: (any Encodable)?
    var usesStoredToken: Bool = true
    var explicitToken: String?
    var retriesWithRefresh = true

    static func login(email: String, password: String) -> Endpoint {
        Endpoint(
            path: "auth/login",
            method: "POST",
            body: LoginPayload(email: email, password: password),
            usesStoredToken: false
        )
    }

    static func requestEmailCode(email: String) -> Endpoint {
        Endpoint(
            path: "auth/email/request",
            method: "POST",
            body: EmailPayload(email: email),
            usesStoredToken: false
        )
    }

    static func verifyEmailCode(code: String, tempToken: String) -> Endpoint {
        Endpoint(
            path: "auth/email/login-verify",
            method: "POST",
            body: CodePayload(code: code),
            usesStoredToken: false,
            explicitToken: tempToken
        )
    }

    static func resendEmailCode(tempToken: String) -> Endpoint {
        Endpoint(
            path: "auth/email/resend",
            method: "POST",
            usesStoredToken: false,
            explicitToken: tempToken
        )
    }

    static func refresh(refreshToken: String) -> Endpoint {
        Endpoint(
            path: "auth/refresh",
            method: "POST",
            body: RefreshPayload(refreshToken: refreshToken),
            usesStoredToken: false
        )
    }

    static var me: Endpoint {
        Endpoint(path: "auth/me", method: "GET")
    }

    static func logout(refreshToken: String?) -> Endpoint {
        Endpoint(
            path: "auth/logout",
            method: "POST",
            body: refreshToken.map { RefreshPayload(refreshToken: $0) },
            retriesWithRefresh: false
        )
    }

    static func organization(id: String) -> Endpoint {
        Endpoint(path: "organizations/\(id)", method: "GET")
    }

    static func changePassword(current: String, new: String) -> Endpoint {
        Endpoint(
            path: "users/me/password",
            method: "POST",
            body: PasswordChangePayload(currentPassword: current, newPassword: new)
        )
    }

    static var myAssignments: Endpoint { assignments(page: 1) }

    static func assignments(page: Int) -> Endpoint {
        Endpoint(path: "fairs/my-assignments", method: "GET", queryItems: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: "100")
        ])
    }

    static func assignment(fairId: String) -> Endpoint {
        Endpoint(path: "fairs/my-assignments/\(fairId)", method: "GET")
    }

    static var myProjects: Endpoint {
        Endpoint(path: "fairs/my-projects", method: "GET")
    }

    static func reviewProjects(fairId: String, scope: ReviewScope = .assigned) -> Endpoint {
        Endpoint(path: "fairs/\(fairId)/review-projects", method: "GET", queryItems:
            scope == .all ? [URLQueryItem(name: "scope", value: "all")] : [])
    }

    static func projectDetail(fairId: String, projectId: String) -> Endpoint {
        Endpoint(path: "fairs/\(fairId)/projects/\(projectId)", method: "GET")
    }

    static func projectRating(fairId: String, projectId: String) -> Endpoint {
        Endpoint(path: "fairs/\(fairId)/projects/\(projectId)/rating", method: "GET")
    }

    static func saveRating(fairId: String, projectId: String, body: ReviewPutBody) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/projects/\(projectId)/rating",
            method: "PUT",
            body: body
        )
    }

}
