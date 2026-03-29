// Pet.swift
// PawHaven
//
// Maps to the `pets` table in Supabase.

import Foundation

struct Pet: Codable, Identifiable, Hashable {
    let id: UUID
    let fosterId: UUID
    var name: String
    var species: PetSpecies
    var breed: String?
    var ageMonths: Int?
    var size: PetSize?
    var gender: PetGender
    var description: String?
    var healthNotes: String?
    var behaviorNotes: String?
    var vaccinated: Bool
    var neutered: Bool
    var status: PetStatus
    var city: String?
    var photos: [String]
    let createdAt: Date

    // Populated via Supabase join: .select("*, foster:users(*)")
    var foster: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case fosterId      = "foster_id"
        case name, species, breed
        case ageMonths     = "age_months"
        case size, gender
        case description
        case healthNotes   = "health_notes"
        case behaviorNotes = "behavior_notes"
        case vaccinated, neutered, status, city, photos
        case createdAt     = "created_at"
        case foster
    }

    // MARK: - Computed helpers

    var coverPhoto: String? { photos.first }

    var ageDisplay: String {
        guard let months = ageMonths else { return "Age unknown" }
        if months < 12 { return "\(months) mo" }
        let years = months / 12
        return years == 1 ? "1 yr" : "\(years) yrs"
    }

    var isNew: Bool {
        (Calendar.current.dateComponents([.hour], from: createdAt, to: .now).hour ?? 25) < 24
    }

    static func == (lhs: Pet, rhs: Pet) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Supporting Enums

enum PetSpecies: String, Codable, CaseIterable {
    case dog, cat, bird, rabbit, other

    var emoji: String {
        switch self {
        case .dog:    return "🐶"
        case .cat:    return "🐱"
        case .bird:   return "🐦"
        case .rabbit: return "🐰"
        case .other:  return "🐾"
        }
    }

    var displayName: String { rawValue.capitalized }
}

enum PetSize: String, Codable, CaseIterable {
    case small, medium, large
    var displayName: String { rawValue.capitalized }
}

enum PetGender: String, Codable, CaseIterable {
    case male, female, unknown
    var displayName: String { rawValue.capitalized }
}

enum PetStatus: String, Codable {
    case available, pending, adopted
}

// MARK: - Filter

struct PetFilters: Equatable {
    var species: PetSpecies?
    var size: PetSize?
}
