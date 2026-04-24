import SwiftUI

// MARK: - Glaido-inspired dark palette (no pink)

struct AppColors {
    // Backgrounds
    static let base         = Color(red: 0.039, green: 0.039, blue: 0.039)   // #0A0A0A
    static let surface      = Color(red: 0.086, green: 0.086, blue: 0.086)   // #161616
    static let surfaceHigh  = Color(red: 0.118, green: 0.118, blue: 0.118)   // #1E1E1E
    static let surfaceHover = Color(red: 0.153, green: 0.153, blue: 0.153)   // #272727

    // Accent – lime / chartreuse (Glaido primary)
    static let accent       = Color(red: 0.710, green: 1.000, blue: 0.000)   // #B5FF00
    static let accentDim    = Color(red: 0.710, green: 1.000, blue: 0.000).opacity(0.15)

    // Text
    static let textPrimary  = Color.white
    static let textSecondary = Color(white: 0.55)
    static let textMuted    = Color(white: 0.33)

    // State
    static let recording    = Color(red: 1.000, green: 0.271, blue: 0.271)   // #FF4545
    static let processing   = Color(red: 0.267, green: 0.533, blue: 1.000)   // #4488FF
    static let success      = Color(red: 0.271, green: 1.000, blue: 0.529)   // #45FF87
    static let warning      = Color(red: 1.000, green: 0.855, blue: 0.000)   // #FFDA00

    // Structure
    static let border       = Color.white.opacity(0.08)
    static let divider      = Color.white.opacity(0.055)
}

// Keep CyberpunkColors as a compatibility alias so existing view code compiles unchanged.
// All values now use the Glaido palette.
struct CyberpunkColors {
    static let neonPink      = AppColors.accent
    static let neonMagenta   = AppColors.accent.opacity(0.75)
    static let neonCyan      = AppColors.textSecondary
    static let neonPurple    = AppColors.processing
    static let darkBg        = AppColors.base
    static let darkBgAlt     = AppColors.surface
    static let cardBg        = AppColors.surfaceHigh
    static let accentGreen   = AppColors.success
    static let accentYellow  = AppColors.warning
    static let recordingRed  = AppColors.recording
    static let processingBlue = AppColors.processing
    static let successGreen  = AppColors.success
    static let textPrimary   = AppColors.textPrimary
    static let textSecondary = AppColors.textSecondary
    static let textMuted     = AppColors.textMuted
}

// MARK: - Gradient presets (kept for compatibility)
struct CyberpunkGradients {
    static let neonPinkMagenta = LinearGradient(
        colors: [AppColors.accent, AppColors.accent.opacity(0.6)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Glow effects — stripped to clean shadows for Glaido aesthetic
extension View {
    @ViewBuilder
    func neonGlow(_ color: Color = AppColors.accent, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.25), radius: radius * 0.5, x: 0, y: 0)
    }

    @ViewBuilder
    func neonGlowIntense(_ color: Color = AppColors.accent) -> some View {
        self.shadow(color: color.opacity(0.35), radius: 8, x: 0, y: 0)
    }
}
