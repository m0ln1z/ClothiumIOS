import SwiftUI

enum BrandTheme {
    // Palette from reference (hex):
    // 01 #292526, 02 #787676, 03 #A3A1A2, 04 #F2F2F2, 05 #121111
    static let neutral01 = Color(red: 41/255, green: 37/255, blue: 38/255)
    static let neutral02 = Color(red: 120/255, green: 118/255, blue: 118/255)
    static let neutral03 = Color(red: 163/255, green: 161/255, blue: 162/255)
    static let neutral04 = Color(red: 242/255, green: 242/255, blue: 242/255)
    static let neutral05 = Color(red: 18/255, green: 17/255, blue: 17/255)

    static let background = neutral04
    static let surface = Color.white
    static let surfaceMuted = neutral04
    static let stroke = neutral03
    static let textPrimary = neutral05
    static let textSecondary = neutral02
    static let accent = neutral05
}

// Backwards compatibility shims so existing code compiles
extension ShapeStyle where Self == LinearGradient {
    static var brandBackground: LinearGradient { LinearGradient(colors: [BrandTheme.background], startPoint: .top, endPoint: .bottom) }
    static var brandAccent: LinearGradient { LinearGradient(colors: [BrandTheme.accent], startPoint: .leading, endPoint: .trailing) }
}


