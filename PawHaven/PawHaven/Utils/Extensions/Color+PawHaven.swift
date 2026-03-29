// Color+PawHaven.swift
// PawHaven

import SwiftUI

// MARK: - Brand Colors
extension Color {
    /// Deep forest green (light) / Lighter green (dark)
    static let phPrimary = Color(light: Color(hex: "2D6A4F"), dark: Color(hex: "52B788"))
    /// Warm amber — same in both modes
    static let phAccent = Color(hex: "F4A261")
    /// Page background
    static let phBackground = Color(light: Color(hex: "FAFAF8"), dark: Color(hex: "111816"))
    /// Card / surface background
    static let phSurface = Color(light: .white, dark: Color(hex: "1C2620"))
    /// Secondary text
    static let phTextSecondary = Color(light: Color(hex: "6B7280"), dark: Color(hex: "9CA3AF"))
    /// Borders and dividers
    static let phBorder = Color(light: Color(hex: "E5E7EB"), dark: Color(hex: "374151"))
    /// Success green
    static let phSuccess = Color(hex: "10B981")
    /// Destructive red
    static let phDestructive = Color(hex: "EF4444")
}

// MARK: - Initializers
extension Color {
    /// Adaptive color — picks light or dark based on current color scheme.
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// 6-digit hex initializer, no alpha (e.g. "2D6A4F").
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >>  8) & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
