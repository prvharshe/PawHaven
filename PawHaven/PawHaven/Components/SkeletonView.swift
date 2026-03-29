// SkeletonView.swift
// PawHaven
//
// Shimmer loading effect. Apply .skeleton() to any view.
// Usage:
//   Rectangle().fill(Color.phBorder).frame(height: 20).skeleton()
//   Text("...").redacted(reason: .placeholder).skeleton()

import SwiftUI

struct SkeletonModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.4), location: 0.4),
                            .init(color: .white.opacity(0.5), location: 0.5),
                            .init(color: .white.opacity(0.4), location: 0.6),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .init(x: phase - 0.4, y: 0.5),
                        endPoint:   .init(x: phase + 0.4, y: 0.5)
                    )
                    .frame(width: geo.size.width * 3)
                    .offset(x: -geo.size.width + geo.size.width * phase * 2)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func skeleton() -> some View {
        modifier(SkeletonModifier())
    }
}

// MARK: - Pet Card Skeleton
struct PetCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.phBorder)
                .aspectRatio(16/9, contentMode: .fill)
                .skeleton()

            VStack(alignment: .leading, spacing: 6) {
                Rectangle().fill(Color.phBorder).frame(width: 120, height: 16).cornerRadius(4).skeleton()
                Rectangle().fill(Color.phBorder).frame(width: 80, height: 12).cornerRadius(4).skeleton()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.phSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
