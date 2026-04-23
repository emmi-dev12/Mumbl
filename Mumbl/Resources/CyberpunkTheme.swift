import SwiftUI

// MARK: - Cyberpunk Neon Color Scheme
struct CyberpunkColors {
    // Primary neon colors
    static let neonPink = Color(red: 1.0, green: 0.0, blue: 0.44)      // #FF006E
    static let neonMagenta = Color(red: 1.0, green: 0.06, blue: 0.94)  // #FF10F0
    static let neonCyan = Color(red: 0.0, green: 1.0, blue: 1.0)       // #00FFFF
    static let neonPurple = Color(red: 0.67, green: 0.0, blue: 1.0)    // #AB00FF
    
    // Background colors
    static let darkBg = Color(red: 0.04, green: 0.06, blue: 0.15)      // #0A0E27 (very dark blue)
    static let darkBgAlt = Color(red: 0.1, green: 0.1, blue: 0.18)     // #1a1a2e
    static let cardBg = Color(red: 0.08, green: 0.10, blue: 0.20)      // #141428
    
    // Accent colors
    static let accentGreen = Color(red: 0.2, green: 1.0, blue: 0.6)    // #33FF99
    static let accentYellow = Color(red: 1.0, green: 0.98, blue: 0.0)  // #FFFA00
    
    // Status colors
    static let recordingRed = Color(red: 1.0, green: 0.0, blue: 0.2)   // #FF0033
    static let processingBlue = Color(red: 0.0, green: 0.75, blue: 1.0) // #00BFFF
    static let successGreen = Color(red: 0.2, green: 1.0, blue: 0.5)   // #33FF80
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textMuted = Color(white: 0.5)
}

// MARK: - Neon Glow Effects
extension View {
    func neonGlow(_ color: Color = CyberpunkColors.neonPink, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color.opacity(0.8), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.5), radius: radius * 1.5, x: 0, y: 0)
    }
    
    func neonGlowIntense(_ color: Color = CyberpunkColors.neonPink) -> some View {
        self
            .shadow(color: color.opacity(1.0), radius: 12, x: 0, y: 0)
            .shadow(color: color.opacity(0.7), radius: 20, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: 30, x: 0, y: 0)
    }
}

// MARK: - Gradient Presets
struct CyberpunkGradients {
    static let neonPinkMagenta = LinearGradient(
        gradient: Gradient(colors: [CyberpunkColors.neonPink, CyberpunkColors.neonMagenta]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let neonPinkCyan = LinearGradient(
        gradient: Gradient(colors: [CyberpunkColors.neonPink, CyberpunkColors.neonCyan]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let purpleMagenta = LinearGradient(
        gradient: Gradient(colors: [CyberpunkColors.neonPurple, CyberpunkColors.neonMagenta]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGradient = LinearGradient(
        gradient: Gradient(colors: [CyberpunkColors.darkBg, CyberpunkColors.darkBgAlt]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
