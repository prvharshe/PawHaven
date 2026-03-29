// ProfileService.swift
// PawHaven

import Foundation
import Supabase

final class ProfileService {
    private let client: SupabaseClient

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Fetch

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        try await client
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    // MARK: - Update

    func updateProfile(
        userId: UUID,
        displayName: String,
        bio: String?,
        city: String?,
        avatarUrl: String?
    ) async throws {
        struct Update: Encodable {
            let displayName: String
            let bio: String?
            let city: String?
            let avatarUrl: String?
            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
                case bio, city
                case avatarUrl = "avatar_url"
            }
        }
        try await client
            .from("users")
            .update(Update(displayName: displayName, bio: bio, city: city, avatarUrl: avatarUrl))
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Availability Toggle (fosters only)

    func setAvailableForIntake(_ available: Bool, userId: UUID) async throws {
        try await client
            .from("users")
            .update(["available_for_intake": available])
            .eq("id", value: userId.uuidString)
            .execute()
    }
}
