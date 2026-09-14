import Foundation

// MARK: - Payloads

private struct LoginPayload: Encodable {
    let email: String
    let password: String
}

private struct CodePayload: Encodable {
    let code: String
}

private struct BackupCodePayload: Encodable {
    let backupCode: String
}

private struct RefreshPayload: Encodable {
    let refreshToken: String
}

private struct DeclarationPayload: Encodable {
    let statement: String
}

private struct EvaluationUpdatePayload: Encodable {
    let scores: [ScoreInput]
    let comment: String?
}

// MARK: - Endpoint

struct Endpoint {

    let path: String
    let method: String

    var queryItems: [URLQueryItem] = []

    var body: (any Encodable)? = nil

    var usesStoredToken: Bool = true

    var explicitToken: String? = nil

    // MARK: - Autenticación

    static func login(
        email: String,
        password: String
    ) -> Endpoint {
        Endpoint(
            path: "auth/login",
            method: "POST",
            body: LoginPayload(
                email: email,
                password: password
            ),
            usesStoredToken: false
        )
    }

    static func verifyTotp(
        code: String,
        tempToken: String
    ) -> Endpoint {
        Endpoint(
            path: "auth/totp/login-verify",
            method: "POST",
            body: CodePayload(
                code: code
            ),
            usesStoredToken: false,
            explicitToken: tempToken
        )
    }

    static func verifyBackupCode(
        code: String,
        tempToken: String
    ) -> Endpoint {
        Endpoint(
            path: "auth/totp/login-verify",
            method: "POST",
            body: BackupCodePayload(
                backupCode: code
            ),
            usesStoredToken: false,
            explicitToken: tempToken
        )
    }

    static func refresh(
        refreshToken: String
    ) -> Endpoint {
        Endpoint(
            path: "auth/refresh",
            method: "POST",
            body: RefreshPayload(
                refreshToken: refreshToken
            ),
            usesStoredToken: false,
            explicitToken: refreshToken
        )
    }

    static var me: Endpoint {
        Endpoint(
            path: "auth/me",
            method: "GET"
        )
    }

    static func logout(
        refreshToken: String?
    ) -> Endpoint {
        Endpoint(
            path: "auth/logout",
            method: "POST",
            body: refreshToken.map {
                RefreshPayload(
                    refreshToken: $0
                )
            },
            usesStoredToken: true
        )
    }

    // MARK: - Ferias

    static var myAssignments: Endpoint {
        Endpoint(
            path: "fairs/my-assignments",
            method: "GET",
            queryItems: [
                URLQueryItem(
                    name: "limit",
                    value: "100"
                )
            ]
        )
    }

    static func declaration(
        fairId: String
    ) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/jury/declaration",
            method: "GET"
        )
    }

    static func signDeclaration(
        fairId: String,
        statement: String
    ) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/jury/declaration",
            method: "POST",
            body: DeclarationPayload(
                statement: statement
            )
        )
    }

    // MARK: - Proyectos

    static func categories(
        fairId: String
    ) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/categories",
            method: "GET"
        )
    }

    static func stands(
        fairId: String
    ) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/stands",
            method: "GET"
        )
    }

    static func projects(
        fairId: String,
        search: String? = nil,
        categoryId: String? = nil,
        standId: String? = nil
    ) -> Endpoint {

        var items = [
            URLQueryItem(
                name: "limit",
                value: "100"
            )
        ]

        if let search, !search.isEmpty {
            items.append(
                URLQueryItem(
                    name: "search",
                    value: search
                )
            )
        }

        if let categoryId {
            items.append(
                URLQueryItem(
                    name: "category_id",
                    value: categoryId
                )
            )
        }

        if let standId {
            items.append(
                URLQueryItem(
                    name: "stand_id",
                    value: standId
                )
            )
        }

        return Endpoint(
            path: "fairs/\(fairId)/projects",
            method: "GET",
            queryItems: items
        )
    }

    static func projectDetail(
        fairId: String,
        projectId: String
    ) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/projects/\(projectId)",
            method: "GET"
        )
    }

    // MARK: - Evaluación

    static func rubric(
        fairId: String
    ) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/rubric",
            method: "GET"
        )
    }

    static func createEvaluation(
        fairId: String,
        input: EvaluationInput
    ) -> Endpoint {
        Endpoint(
            path: "fairs/\(fairId)/evaluations",
            method: "POST",
            body: input
        )
    }

    static func updateEvaluation(
            fairId: String,
            evaluationId: String,
            input: EvaluationInput
        ) -> Endpoint {
            Endpoint(
                path: "fairs/\(fairId)/evaluations/\(evaluationId)",
                method: "PUT",
                body: input
            )
        }
    }
