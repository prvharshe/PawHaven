// PHButton.swift
// PawHaven

import SwiftUI

enum PHButtonStyle {
    case primary, secondary, ghost, destructive
}

struct PHButton: View {
    let title: String
    let style: PHButtonStyle
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(progressTint)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 52)
            .padding(.horizontal, isFullWidth ? 0 : 24)
        }
        .buttonStyle(PHButtonInternalStyle(style: style))
        .disabled(isLoading)
    }

    private var progressTint: Color {
        style == .primary || style == .destructive ? .white : .phPrimary
    }
}

private struct PHButtonInternalStyle: ButtonStyle {
    let style: PHButtonStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(background(pressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch style {
        case .primary:     return .white
        case .secondary:   return .phPrimary
        case .ghost:       return .phPrimary
        case .destructive: return .white
        }
    }

    private func background(pressed: Bool) -> some View {
        Group {
            switch style {
            case .primary:
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.phAccent.opacity(pressed ? 0.85 : 1))
            case .secondary:
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.phPrimary, lineWidth: 1.5)
                    .background(Color.phSurface)
            case .ghost:
                Color.clear
            case .destructive:
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.phDestructive.opacity(pressed ? 0.85 : 1))
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PHButton(title: "Adopt Me", style: .primary) {}
        PHButton(title: "Save", style: .secondary) {}
        PHButton(title: "Learn More", style: .ghost, isFullWidth: false) {}
        PHButton(title: "Report", style: .destructive) {}
        PHButton(title: "Loading...", style: .primary, isLoading: true) {}
    }
    .padding()
}
