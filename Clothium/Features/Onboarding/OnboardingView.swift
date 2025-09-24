import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    var onFinished: () -> Void

    init(user: AuthUser, onFinished: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(user: user))
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            BrandTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Ваш стиль")
                    .font(.largeTitle.bold())
                    .foregroundStyle(BrandTheme.textPrimary)
                    .padding(.top, 8)

                Text("Выберите один вариант или больше и мы подберем капсулу рекомендаций")
                    .foregroundStyle(BrandTheme.textSecondary)
                    .font(.subheadline)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(viewModel.options) { option in
                            styleCard(option)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button(action: submit) {
                    HStack {
                        if viewModel.isSubmitting { ProgressView().tint(.white) }
                        Text("Продолжить")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selected.isEmpty ? Color.black.opacity(0.5) : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .disabled(viewModel.selected.isEmpty || viewModel.isSubmitting)
            }
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.isCompleted) { _, done in
            if done { onFinished() }
        }
    }

    private func submit() {
        Task { await viewModel.submit() }
    }

    @ViewBuilder
    private func styleCard(_ option: StyleOption) -> some View {
        let isSelected = viewModel.selected.contains(option)
        Button {
            viewModel.toggle(option)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(option.title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.textPrimary)
                Text(option.subtitle)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.textSecondary)
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .black : BrandTheme.textSecondary)
                        .font(.title3)
                        .padding(6)
                        .background(isSelected ? Color.white : Color.clear)
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(BrandTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? BrandTheme.textPrimary.opacity(0.8) : BrandTheme.stroke, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    OnboardingView(user: .init(id: "1", email: "demo@clothium.app")) {}
}


