import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль."
        case .unknown:
            return "Неизвестная ошибка. Повторите попытку позже."
        }
    }
}

struct AuthUser: Identifiable, Equatable {
    let id: String
    let email: String
}

protocol AuthServicing {
    func signIn(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String) async throws -> AuthUser
    func signInWithApple(token: String) async throws -> AuthUser
    func signOut() async
}

final class AuthService: AuthServicing {
    static let shared = AuthService()

    private init() {}

    private var currentUser: AuthUser?

    func signIn(email: String, password: String) async throws -> AuthUser {
        try await Task.sleep(nanoseconds: 600_000_000)
        guard !email.isEmpty, !password.isEmpty else { throw AuthError.invalidCredentials }
        let user = AuthUser(id: UUID().uuidString, email: email.lowercased())
        currentUser = user
        return user
    }

    func signUp(email: String, password: String) async throws -> AuthUser {
        try await Task.sleep(nanoseconds: 800_000_000)
        guard email.contains("@"), password.count >= 6 else { throw AuthError.invalidCredentials }
        let user = AuthUser(id: UUID().uuidString, email: email.lowercased())
        currentUser = user
        return user
    }

    func signInWithApple(token: String) async throws -> AuthUser {
        try await Task.sleep(nanoseconds: 500_000_000)
        guard !token.isEmpty else { throw AuthError.unknown }
        let user = AuthUser(id: UUID().uuidString, email: "apple_user@stub")
        currentUser = user
        return user
    }

    func signOut() async {
        currentUser = nil
    }
}


