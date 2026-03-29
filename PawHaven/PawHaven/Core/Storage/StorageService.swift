// StorageService.swift
// PawHaven
//
// Uploads images to Supabase Storage and returns public URLs.
// Buckets required (create in Supabase Dashboard → Storage):
//   • "pet-photos"  — public
//   • "avatars"     — public

import UIKit
import Supabase

final class StorageService {
    private let client: SupabaseClient

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Pet Photos

    /// Compress + upload a single pet photo. Returns the public URL string.
    func uploadPetPhoto(_ image: UIImage, petId: UUID) async throws -> String {
        let data = ImageCompressor.compress(image)
        let path = "\(petId.uuidString)/\(UUID().uuidString).jpg"

        try await client.storage
            .from("pet-photos")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))

        return try publicURL(bucket: "pet-photos", path: path)
    }

    /// Upload multiple pet photos concurrently. Returns ordered URL array.
    func uploadPetPhotos(_ images: [UIImage], petId: UUID) async throws -> [String] {
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (i, image) in images.enumerated() {
                group.addTask { [weak self] in
                    guard let self else { throw StorageError.unknown }
                    let url = try await self.uploadPetPhoto(image, petId: petId)
                    return (i, url)
                }
            }
            var results: [(Int, String)] = []
            for try await pair in group { results.append(pair) }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    // MARK: - Avatars

    /// Compress + upload a user avatar. Returns the public URL string.
    func uploadAvatar(_ image: UIImage, userId: UUID) async throws -> String {
        let data = ImageCompressor.compress(image, maxBytes: 400_000, maxDimension: 400)
        let path = "\(userId.uuidString)/avatar.jpg"

        try await client.storage
            .from("avatars")
            .upload(path, data: data, options: FileOptions(
                contentType: "image/jpeg",
                upsert: true          // overwrite existing avatar
            ))

        return try publicURL(bucket: "avatars", path: path)
    }

    // MARK: - Helpers

    private func publicURL(bucket: String, path: String) throws -> String {
        try client.storage.from(bucket).getPublicURL(path: path).absoluteString
    }
}

enum StorageError: Error {
    case compressionFailed
    case unknown
}
