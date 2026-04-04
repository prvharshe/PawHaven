// Pet.swift
// PawHaven
//
// Maps to the `pets` table in Supabase.

import Foundation
import CoreLocation

// MARK: - GeoPoint (PostGIS geography → GeoJSON decode)

struct GeoPoint: Codable {
    let type: String
    let coordinates: [Double] // GeoJSON: [longitude, latitude]

    var latitude:  Double { coordinates.count > 1 ? coordinates[1] : 0 }
    var longitude: Double { coordinates.first ?? 0 }

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - GeoPointInsert (Swift → Supabase PostgREST insert)
// PostgREST requires WKT format for geography columns, not GeoJSON.

struct GeoPointInsert: Encodable {
    let longitude: Double
    let latitude:  Double

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("POINT(\(longitude) \(latitude))")
    }
}

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
    var urgent: Bool
    var city: String?
    var locationPoint: GeoPoint?
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
        case vaccinated, neutered, status, urgent, city
        case locationPoint = "location_point"
        case photos
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

    var coordinate: CLLocationCoordinate2D? {
        locationPoint?.clCoordinate
    }

    static func == (lhs: Pet, rhs: Pet) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Custom Decodable (extension preserves the memberwise initializer)
// locationPoint uses try? so an unexpected PostgREST wire format
// (WKB hex, WKT string, etc.) degrades to nil instead of crashing the decode.

extension Pet {
    init(from decoder: Decoder) throws {
        let c         = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(UUID.self,         forKey: .id)
        fosterId      = try c.decode(UUID.self,         forKey: .fosterId)
        name          = try c.decode(String.self,       forKey: .name)
        species       = try c.decode(PetSpecies.self,   forKey: .species)
        breed         = try c.decodeIfPresent(String.self,      forKey: .breed)
        ageMonths     = try c.decodeIfPresent(Int.self,         forKey: .ageMonths)
        size          = try c.decodeIfPresent(PetSize.self,     forKey: .size)
        gender        = try c.decode(PetGender.self,    forKey: .gender)
        description   = try c.decodeIfPresent(String.self,      forKey: .description)
        healthNotes   = try c.decodeIfPresent(String.self,      forKey: .healthNotes)
        behaviorNotes = try c.decodeIfPresent(String.self,      forKey: .behaviorNotes)
        vaccinated    = try c.decode(Bool.self,          forKey: .vaccinated)
        neutered      = try c.decode(Bool.self,          forKey: .neutered)
        status        = try c.decode(PetStatus.self,     forKey: .status)
        urgent        = (try? c.decode(Bool.self,        forKey: .urgent)) ?? false
        city          = try c.decodeIfPresent(String.self,      forKey: .city)
        locationPoint = try? c.decode(GeoPoint.self,     forKey: .locationPoint)
        photos        = try c.decode([String].self,      forKey: .photos)
        createdAt     = try c.decode(Date.self,          forKey: .createdAt)
        foster        = try c.decodeIfPresent(UserProfile.self, forKey: .foster)
    }
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
    var species:    PetSpecies?
    var size:       PetSize?
    var gender:     PetGender?
    var vaccinated: Bool?
    var neutered:   Bool?
}
