import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    var onAuthenticated: (AuthUser) -> Void

    var body: some View {
        ZStack {
            BrandTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Text(viewModel.mode == .signIn ? "Вход" : "Регистрация")
                    .font(.largeTitle.bold())
                    .foregroundStyle(BrandTheme.textPrimary)

                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(BrandTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrandTheme.stroke, lineWidth: 1))

                    SecureField("Пароль", text: $viewModel.password)
                        .padding()
                        .background(BrandTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrandTheme.stroke, lineWidth: 1))

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: submit) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white) }
                            Text(viewModel.mode == .signIn ? "Войти" : "Создать аккаунт")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background((viewModel.isFormValid ? BrandTheme.accent : BrandTheme.stroke).opacity(viewModel.isFormValid ? 1 : 0.8))
                        .clipShape(Capsule())
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)

                    HStack {
                        Rectangle().fill(BrandTheme.stroke).frame(height: 1)
                        Text("или")
                            .foregroundStyle(BrandTheme.textSecondary)
                            .font(.subheadline)
                        Rectangle().fill(BrandTheme.stroke).frame(height: 1)
                    }

                    AppleSignInButton { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                               let tokenData = credential.identityToken,
                               let token = String(data: tokenData, encoding: .utf8) {
                                Task { await viewModel.signInWithApple(token: token) }
                            }
                        case .failure(let error):
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                    .frame(height: 50)

                    Button(action: { viewModel.toggleMode() }) {
                        Text(viewModel.mode == .signIn ? "Нет аккаунта? Зарегистрируйтесь" : "Уже есть аккаунт? Войти")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(BrandTheme.textSecondary)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .glassCard(cornerRadius: 20)
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .onChange(of: viewModel.user) { _, newValue in
            if let user = newValue { onAuthenticated(user) }
        }
    }

    private func submit() {
        Task { await viewModel.submit() }
    }
}

#Preview {
    AuthView { _ in }
}

