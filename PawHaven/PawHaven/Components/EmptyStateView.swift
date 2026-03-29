// EmptyStateView.swift
// PawHaven

import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var ctaTitle: String?
    var ctaAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundStyle(Color.phPrimary.opacity(0.6))

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.phTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let ctaTitle, let ctaAction {
                PHButton(title: ctaTitle, style: .primary, isFullWidth: false, action: ctaAction)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "pawprint",
        title: "No pets nearby",
        subtitle: "Try expanding your search radius or check back soon.",
        ctaTitle: "Expand Radius",
        ctaAction: {}
    )
}
