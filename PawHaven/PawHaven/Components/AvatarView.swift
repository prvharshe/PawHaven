// AvatarView.swift
// PawHaven

import SwiftUI

struct AvatarView: View {
    let url: String?
    var size: CGFloat = 44
    var initials: String = "?"

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.phBorder, lineWidth: 1))
    }

    private var initialsView: some View {
        ZStack {
            Color.phPrimary.opacity(0.15)
            Text(initials.prefix(2).uppercased())
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(Color.phPrimary)
        }
    }
}

extension UserProfile {
    var initials: String {
        displayName
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
}

#Preview {
    HStack(spacing: 12) {
        AvatarView(url: nil, size: 36, initials: "JS")
        AvatarView(url: nil, size: 44, initials: "Pranav Harshe")
        AvatarView(url: nil, size: 60, initials: "A")
    }
    .padding()
}
