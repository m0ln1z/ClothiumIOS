import SwiftUI

struct WelcomeView: View {
    var onStartAuth: () -> Void

    var body: some View {
        ZStack {
            BrandTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
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


