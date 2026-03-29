// PHTag.swift
// PawHaven
//
// Pill-shaped tag/chip. Color-coded by type.

import SwiftUI

enum PHTagType {
    case health      // green — vaccinated, neutered
    case behavior    // blue  — good with kids, etc.
    case neutral     // gray  — species, size, age
    case status      // amber — new, adopted, pending
}

struct PHTag: View {
    let text: String
    var type: PHTagType = .neutral
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(background)
        .clipShape(Capsule())
    }

    private var foreground: Color {
        switch type {
        case .health:   return Color(hex: "065F46")
        case .behavior: return Color(hex: "1E40AF")
        case .neutral:  return Color.phTextSecondary
        case .status:   return Color(hex: "92400E")
        }
    }

    private var background: Color {
        switch type {
        case .health:   return Color(hex: "D1FAE5")
        case .behavior: return Color(hex: "DBEAFE")
        case .neutral:  return Color.phBorder
        case .status:   return Color(hex: "FEF3C7")
        }
    }
}

#Preview {
    HStack {
        PHTag(text: "Vaccinated", type: .health, icon: "checkmark.shield.fill")
        PHTag(text: "Dog", type: .neutral, icon: "pawprint.fill")
        PHTag(text: "New", type: .status)
    }
    .padding()
}
