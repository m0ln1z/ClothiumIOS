import SwiftUI

struct OnboardingIntroView: View {
    var onContinue: () -> Void

    @State private var animateIcon = false
    @State private var showContent = false
    @State private var progress: Double = 0
    @State private var didContinue = false

    var body: some View {
        ZStack {
            // Подложка в стиле приложения
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

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                // Анимированная иконка
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
                    .scaleEffect(animateIcon ? 1.05 : 0.95)
                    .shadow(color: .blue.opacity(0.13), radius: 18, x: 0, y: 8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                    .onAppear { animateIcon = true }

                VStack(spacing: 8) {
                    Text("Небольшой онбординг")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.textPrimary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 8)
                        .animation(.easeInOut(duration: 0.35).delay(0.05), value: showContent)

                    Text("Ответьте на несколько вопросов, и мы подберём идеальные образы под ваш стиль.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 8)
                        .animation(.easeInOut(duration: 0.35).delay(0.12), value: showContent)
                }

                // Прогресс-индикатор
                VStack(spacing: 10) {
                    ProgressView(value: progress)
                        .tint(BrandTheme.accent)
                        .frame(maxWidth: 300)
                    Text("Подготовка…")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.textSecondary)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3).delay(0.2), value: showContent)
                }
                .padding(.top, 8)

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            // Плавное появление контента
            showContent = true

            // Линейная анимация прогресса и автопереход через 5 сек
            withAnimation(.linear(duration: 5.0)) { progress = 1.0 }
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                continueNow()
            }
        }
    }

    private func continueNow() {
        guard !didContinue else { return }
        didContinue = true
        onContinue()
    }
}

#Preview {
    OnboardingIntroView { }
}
