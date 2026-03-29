// ImageCompressor.swift
// PawHaven
//
// Downsample and JPEG-compress a UIImage before uploading to Supabase Storage.
// Target: ≤ 800 KB per image, max 1200px on the longest side.

import UIKit

enum ImageCompressor {

    static func compress(_ image: UIImage, maxBytes: Int = 800_000, maxDimension: CGFloat = 1200) -> Data {
        let resized = resize(image, maxDimension: maxDimension)

        // Start at 0.8 quality, step down until under budget
        var quality: CGFloat = 0.8
        var data = resized.jpegData(compressionQuality: quality) ?? Data()

        while data.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            data = resized.jpegData(compressionQuality: quality) ?? data
        }

        return data
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
