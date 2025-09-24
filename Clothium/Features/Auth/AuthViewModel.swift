import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode { case signIn, signUp }

    @Published var mode: Mode = .signIn
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var user: AuthUser?

    private let service: AuthServicing

    init(service: AuthServicing? = nil) {
        self.service = service ?? AuthService.shared
    }

    var isEmailValid: Bool { email.contains("@") && email.contains(".") }
    var isPasswordValid: Bool { password.count >= 6 }
    var isFormValid: Bool {
        switch mode {
        case .signIn: return !email.isEmpty && !password.isEmpty
        case .signUp: return isEmailValid && isPasswordValid
        }
    }

    func toggleMode() { mode = (mode == .signIn ? .signUp : .signIn) }

    func submit() async {
        guard isFormValid else { return }
        isLoading = true
        errorMessage = nil
        do {
            switch mode {
            case .signIn:
                user = try await service.signIn(email: email, password: password)
            case .signUp:
                user = try await service.signUp(email: email, password: password)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func signInWithApple(token: String) async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await service.signInWithApple(token: token)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}


