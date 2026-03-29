// MessageBubble.swift
// PawHaven

import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isFromMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isFromMe { Spacer(minLength: 60) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 3) {
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(isFromMe ? Color.white : Color.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.phPrimary : Color.phSurface)
                    .clipShape(BubbleShape(isFromMe: isFromMe))
                    .overlay(
                        BubbleShape(isFromMe: isFromMe)
                            .stroke(isFromMe ? Color.clear : Color.phBorder, lineWidth: 1)
                    )

                Text(message.createdAt.timeDisplay)
                    .font(.caption2)
                    .foregroundStyle(Color.phTextSecondary)
                    .padding(isFromMe ? .trailing : .leading, 4)
            }

            if !isFromMe { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Bubble tail shape

private struct BubbleShape: Shape {
    let isFromMe: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tail:   CGFloat = 6
        var path = Path()

        if isFromMe {
            path.addRoundedRect(
                in: CGRect(x: rect.minX, y: rect.minY, width: rect.width - tail, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
            // Tail bottom-right
            path.move(to: CGPoint(x: rect.maxX - tail - radius, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - tail, y: rect.maxY - radius * 0.6))
        } else {
            path.addRoundedRect(
                in: CGRect(x: rect.minX + tail, y: rect.minY, width: rect.width - tail, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
            // Tail bottom-left
            path.move(to: CGPoint(x: rect.minX + tail + radius, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + tail, y: rect.maxY - radius * 0.6))
        }
        return path
    }
}

// MARK: - Date separator

struct MessageDateSeparator: View {
    let date: Date

    var body: some View {
        Text(date.shortDisplay)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(Color.phTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.phBorder.opacity(0.5))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }
}
