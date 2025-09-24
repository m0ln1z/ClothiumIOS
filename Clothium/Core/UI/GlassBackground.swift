import SwiftUI

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.22
    var strokeOpacity: Double = 0.5

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Градиент для объёма
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.60),
                            Color.white.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .blur(radius: 0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                // Внешний border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(BrandTheme.stroke.opacity(strokeOpacity), lineWidth: 1)
            )
            .overlay(
                // Внутреннее свечение
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 2)
                    .blur(radius: 0.8)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 22, x: 0, y: 12)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}
