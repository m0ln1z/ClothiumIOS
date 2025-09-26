import SwiftUI
import AuthenticationServices

private struct CardBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var animateIcon = false
    @FocusState private var focusedField: Field?

    // Keyboard state
    @State private var keyboardHeight: CGFloat = 0
    @State private var cardBottomY: CGFloat = 0
    @State private var didAutoFocus = false

    var onAuthenticated: (AuthUser) -> Void

    private enum Field {
        case email, password
    }

    private var isEditing: Bool { focusedField != nil }

    // Сколько нужно поднять карточку, чтобы она не перекрывалась клавиатурой
    private var cardLiftOffset: CGFloat {
        let screenH = UIScreen.main.bounds.height
        // хотим, чтобы cardBottomY + (-offset) <= (screenH - keyboardHeight) - 8
        // => offset >= cardBottomY + 8 - (screenH - keyboardHeight)
        let required = cardBottomY + 8 - (screenH - keyboardHeight)
        return max(0, required)
    }

    var body: some View {
        ZStack {
            // Стилизованная подложка
            BrandTheme.background
                .ignoresSafeArea()
                .overlay(
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 360, height: 360)
                            .blur(radius: 90)
                            .offset(x: -140, y: -220)

                        Circle()
                            .fill(BrandTheme.accent.opacity(0.08))
                            .frame(width: 420, height: 420)
                            .blur(radius: 110)
                            .offset(x: 160, y: 180)
                    }
                )

            VStack(spacing: 16) {
                // Верх: иконка + (скрываемый) заголовок
                VStack(spacing: 10) {
                    Image(systemName: "tshirt.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 74, height: 74)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, BrandTheme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(animateIcon ? 8 : -8))
                        .scaleEffect(animateIcon ? 1.02 : 0.98) // мягкая анимация, чтобы не грузить layout
                        .shadow(color: .blue.opacity(0.13), radius: 18, x: 0, y: 8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                        .onAppear { animateIcon = true }

                    if !isEditing {
                        Text(viewModel.mode == .signIn ? "Вход" : "Регистрация")
                            .font(.largeTitle.bold())
                            .foregroundStyle(BrandTheme.textPrimary)
                            .transition(.opacity)
                    }
                }
                .padding(.top, isEditing ? 0 : 6)

                // Карточка формы (без скролла)
                VStack(spacing: 16) {
                    // Поле почты
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundStyle(BrandTheme.textSecondary)
                        TextField("Введите почту", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }

                        if focusedField == .email {
                            Button {
                                focusedField = nil
                            } label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(BrandTheme.textSecondary)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Скрыть клавиатуру")
                        }
                    }
                    .padding(14)
                    .background(BrandTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrandTheme.stroke, lineWidth: 1))

                    // Поле пароля
                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .foregroundStyle(BrandTheme.textSecondary)
                        SecureField("Введите пароль", text: $viewModel.password)
                            .textContentType(.password)
                            .submitLabel(viewModel.mode == .signIn ? .go : .join)
                            .focused($focusedField, equals: .password)
                            .onSubmit(submit)

                        if focusedField == .password {
                            Button {
                                focusedField = nil
                            } label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(BrandTheme.textSecondary)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Скрыть клавиатуру")
                        }
                    }
                    .padding(14)
                    .background(BrandTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrandTheme.stroke, lineWidth: 1))

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Основная кнопка (внутри карточки)
                    Button(action: submit) {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(viewModel.mode == .signIn ? "Войти" : "Создать аккаунт")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(
                            (viewModel.isFormValid ? BrandTheme.accent : BrandTheme.stroke)
                                .opacity(viewModel.isFormValid ? 1 : 0.8)
                        )
                        .clipShape(Capsule())
                        .shadow(color: BrandTheme.accent.opacity(viewModel.isFormValid ? 0.15 : 0), radius: 12, x: 0, y: 6)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)

                    // Разделитель
                    HStack {
                        Rectangle().fill(BrandTheme.stroke).frame(height: 1)
                        Text("или")
                            .foregroundStyle(BrandTheme.textSecondary)
                            .font(.subheadline)
                        Rectangle().fill(BrandTheme.stroke).frame(height: 1)
                    }
                    .padding(.top, 4)

                    // Sign in with Apple
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Переключатель режима — выделяем слова действия цветом
                    Button(action: { viewModel.toggleMode() }) {
                        HStack(spacing: 4) {
                            if viewModel.mode == .signIn {
                                Text("Нет аккаунта?")
                                    .foregroundStyle(BrandTheme.textSecondary)
                                Text("Зарегистрируйтесь")
                                    .foregroundStyle(Color.blue)
                                    .fontWeight(.semibold)
                                    .underline(true, color: .blue)
                            } else {
                                Text("Уже есть аккаунт?")
                                    .foregroundStyle(BrandTheme.textSecondary)
                                Text("Войти")
                                    .foregroundStyle(Color.blue)
                                    .fontWeight(.semibold)
                                    .underline(true, color: .blue)
                            }
                        }
                        .font(.footnote)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .glassCard(cornerRadius: 20)
                .padding(.horizontal, 20)
                // Поднимаем карточку только настолько, чтобы не перекрывала клавиатуру
                .offset(y: -cardLiftOffset)
                // Измеряем нижнюю границу карточки
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: CardBottomKey.self, value: proxy.frame(in: .global).maxY)
                    }
                )

                Spacer(minLength: 0)
            }
        }
        // Не даём системе сдвигать весь экран при показе клавиатуры
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onPreferenceChange(CardBottomKey.self) { cardBottomY = $0 }
        .onChange(of: viewModel.user) { _, newValue in
            if let user = newValue { onAuthenticated(user) }
        }
        .onAppear {
            autoFocusOnce()
        }
        // Отслеживаем клавиатуру
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard
                let info = notification.userInfo,
                let endFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            else { return }

            let screenHeight = UIScreen.main.bounds.height
            keyboardHeight = max(0, screenHeight - endFrame.origin.y)

            withAnimation(.easeOut(duration: duration)) {
                // только обновляем высоту клавиатуры — offset посчитается из cardBottomY
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
            guard
                let info = notification.userInfo,
                let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            else { return }
            withAnimation(.easeOut(duration: duration)) {
                keyboardHeight = 0
            }
        }
    }

    private func submit() {
        Task { await viewModel.submit() }
    }

    // Автофокус один раз, через ~1мс (чтобы не конфликтовать с переходом)
    private func autoFocusOnce() {
        guard !didAutoFocus else { return }
        didAutoFocus = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000) // ~1 мс
            focusedField = .email
        }
    }
}

#Preview {
    AuthView { _ in }
}
