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

private struct DeclarationPayload: Encodable {
    let statement: String
}

struct RubricResponseBody: Encodable {
    let criterionId: String
    let checked: Bool

    enum CodingKeys: String, CodingKey {
        case criterionId = "criterion_id"
        case checked
    }
}

struct RubricPutBody: Encodable {
    let responses: [RubricResponseBody]
    let finalize: Bool
}

private struct VotePayload: Encodable {
    let projectId: String

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
    }
}

struct Endpoint {
    let path: String
    let method: String
    var queryItems: [URLQueryItem] = []
    var body: (any Encodable)?
    var usesStoredToken: Bool = true
    var explicitToken: String?

    static func login(email: String, password: String) -> Endpoint {
        Endpoint(
            path: "auth/login",
            method: "POST",
            body: LoginPayload(email: email, password: password),
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

    static func resendEmailCode(email: String) -> Endpoint {
        Endpoint(
            path: "auth/email/resend",
            method: "POST",
            body: EmailPayload(email: email),
            usesStoredToken: false
        )
    }

    static func organization(id: String) -> Endpoint {
        Endpoint(path: "organizations/\(id)", method: "GET")
    }

    static var myAssignments: Endpoint {
        Endpoint(path: "fairs/my-assignments", method: "GET")
    }

    static func assignment(fairId: String) -> Endpoint {
        Endpoint(path: "fairs/my-assignments/\(fairId)", method: "GET")
    }

    static func myProgress(fairId: String) -> Endpoint {
        Endpoint(path: "fairs/my-progress/\(fairId)", method: "GET")
    }

    static func declaration(fairId: String) -> Endpoint {
        Endpoint(path: "fairs/\(fairId)/jury/declaration", method: "GET")
    }

    static func signDeclaration(fairId: String, statement: String) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/jury/declaration",
            method: "POST",
            body: DeclarationPayload(statement: statement)
        )
    }

    static func projects(
        fairId: String,
        search: String? = nil,
        categoryId: String? = nil,
        standId: String? = nil
    ) -> Endpoint {
        var items: [URLQueryItem] = []
        if let search, !search.isEmpty {
            items.append(URLQueryItem(name: "search", value: search))
        }
        if let categoryId {
            items.append(URLQueryItem(name: "category_id", value: categoryId))
        }
        if let standId {
            items.append(URLQueryItem(name: "stand_id", value: standId))
        }
        return Endpoint(
            path: "fairs/\(fairId)/projects",
            method: "GET",
            queryItems: items
        )
    }

    static func projectDetail(fairId: String, projectId: String) -> Endpoint {
        Endpoint(path: "fairs/\(fairId)/projects/\(projectId)", method: "GET")
    }

    static func projectRubric(fairId: String, projectId: String) -> Endpoint {
        Endpoint(path: "fairs/\(fairId)/projects/\(projectId)/rubric", method: "GET")
    }

    static func saveRubric(fairId: String, projectId: String, body: RubricPutBody) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/projects/\(projectId)/rubric",
            method: "PUT",
            body: body
        )
    }

    static func myRubrics(fairId: String) -> Endpoint {
        Endpoint(path: "fairs/\(fairId)/my-rubrics", method: "GET")
    }

    static func votingStatus(fairId: String) -> Endpoint {
        Endpoint(path: "fairs/\(fairId)/voting/status", method: "GET")
    }

    static func castVote(fairId: String, projectId: String) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/votes",
            method: "POST",
            body: VotePayload(projectId: projectId)
        )
    }
}
