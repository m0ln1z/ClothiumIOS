import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            BrandTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(BrandTheme.accent)
                    .scaleEffect(1.2)

                Text("Загрузка…")
                    .foregroundStyle(BrandTheme.textSecondary)
            }
            .padding()
            .glassCard(cornerRadius: 20)
            .padding(32)
            .opacity(isAnimating ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) { isAnimating = true }
            }
        }
    }
}

#Preview { SplashView() }


