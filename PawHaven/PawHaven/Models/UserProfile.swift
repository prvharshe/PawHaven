// UserProfile.swift
// PawHaven
//
// Maps to the `users` table in Supabase.
// Named UserProfile to avoid conflict with Supabase's internal User type.

import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var role: UserRole
    var displayName: String
    var bio: String?
    var avatarUrl: String?
    var city: String?
    var verified: Bool
    var availableForIntake: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case displayName        = "display_name"
        case bio
        case avatarUrl          = "avatar_url"
        case city
        case verified
        case availableForIntake = "available_for_intake"
        case createdAt          = "created_at"
    }
}

enum UserRole: String, Codable, CaseIterable {
    case foster
    case adopter
    case both

    var displayName: String {
        switch self {
        case .foster:  return "I Foster Animals"
        case .adopter: return "I Want to Adopt"
        case .both:    return "Both"
        }
    }

    var shortName: String {
        switch self {
        case .foster:  return "Foster"
        case .adopter: return "Adopter"
        case .both:    return "Foster & Adopter"
        }
    }
}
