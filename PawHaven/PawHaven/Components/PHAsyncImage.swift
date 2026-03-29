// PHAsyncImage.swift
// PawHaven
//
// Async image with skeleton loading state and fallback.
// Append Supabase image transform params for sized thumbnails:
//   url + "?width=600&quality=75"

import SwiftUI

struct PHAsyncImage: View {
    let url: String?
    var contentMode: ContentMode = .fill
    var fallbackIcon: String = "pawprint.fill"

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        skeletonPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        fallbackView
                    @unknown default:
                        skeletonPlaceholder
                    }
                }
            } else {
                fallbackView
            }
        }
    }

    private var skeletonPlaceholder: some View {
        Rectangle()
            .fill(Color.phBorder)
            .skeleton()
    }

    private var fallbackView: some View {
        ZStack {
            Color.phBorder.opacity(0.4)
            Image(systemName: fallbackIcon)
                .font(.system(size: 32))
                .foregroundStyle(Color.phTextSecondary)
        }
    }
}

// MARK: - Convenience URL Builder
extension String {
    /// Appends Supabase Storage image transform parameters.
    func supabaseThumbnail(width: Int = 600, quality: Int = 75) -> String {
        "\(self)?width=\(width)&quality=\(quality)"
    }
}

#Preview {
    PHAsyncImage(url: nil)
        .frame(width: 200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
