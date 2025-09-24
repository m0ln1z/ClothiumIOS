import SwiftUI

struct WelcomeView: View {
    var onStartAuth: () -> Void

    @State private var animate = false

    var body: some View {
        ZStack {
            BrandTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
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
                        .rotationEffect(.degrees(animate ? 8 : -8))
                        .scaleEffect(animate ? 1.05 : 0.95)
                        .shadow(color: .blue.opacity(0.13), radius: 18, x: 0, y: 8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
                        .onAppear { animate = true }

                    Text("Clothium")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.textPrimary)
                    Text("Ваша капсула стиля")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BrandTheme.textSecondary)
                }

                Spacer()

                Button(action: onStartAuth) {
                    Text("Продолжить")
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(BrandTheme.accent))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    WelcomeView(onStartAuth: {})
}
