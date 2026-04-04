// Pet.swift
// PawHaven
//
// Maps to the `pets` table in Supabase.

import Foundation
import CoreLocation

// MARK: - GeoPoint (PostGIS geography → decode)
//
// PostgREST returns geography columns as EWKB hex strings
// (e.g. "0101000020E6100000..."), NOT as GeoJSON objects.
// This decoder handles both formats so the map pins work.

struct GeoPoint: Codable {
    let longitude: Double
    let latitude:  Double

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: Codable

    init(from decoder: Decoder) throws {
        // 1. Try EWKB hex string (what PostgREST actually returns)
        if let single = try? decoder.singleValueContainer(),
           let hex = try? single.decode(String.self),
           let coords = GeoPoint.parseEWKB(hex) {
            longitude = coords.0
            latitude  = coords.1
            return
        }
        // 2. Try GeoJSON object {"type":"Point","coordinates":[lng,lat]}
        struct GeoJSON: Decodable {
            let coordinates: [Double]
        }
        if let container = try? decoder.singleValueContainer(),
           let json = try? JSONDecoder().decode(GeoJSON.self,
               from: (try? container.decode(String.self))?.data(using: .utf8) ?? Data()) {
            guard json.coordinates.count >= 2 else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "")) }
            longitude = json.coordinates[0]
            latitude  = json.coordinates[1]
            return
        }
        // 3. Try embedded GeoJSON object directly
        struct GeoJSONKeyed: Decodable {
            let coordinates: [Double]
            enum CodingKeys: String, CodingKey { case coordinates }
        }
        let keyed = try GeoJSONKeyed(from: decoder)
        guard keyed.coordinates.count >= 2 else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "GeoPoint: no coordinates"))
        }
        longitude = keyed.coordinates[0]
        latitude  = keyed.coordinates[1]
    }

    func encode(to encoder: Encoder) throws {
        // Encode back as GeoJSON object for any round-trip writes
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode("Point", forKey: .type)
        try c.encode([longitude, latitude], forKey: .coordinates)
    }

    private enum CodingKeys: String, CodingKey { case type, coordinates }

    // MARK: EWKB Parser
    // Handles Extended WKB (with optional SRID) in little-endian or big-endian byte order.

    private static func parseEWKB(_ hex: String) -> (Double, Double)? {
        let bytes = stride(from: 0, to: hex.count, by: 2).compactMap { i -> UInt8? in
            let s = hex.index(hex.startIndex, offsetBy: i)
            let e = hex.index(s, offsetBy: 2)
            return UInt8(hex[s..<e], radix: 16)
        }
        guard bytes.count >= 21 else { return nil }

        let le = bytes[0] == 1   // byte order: 1 = little-endian

        // Read UInt32 at offset
        func u32(_ off: Int) -> UInt32 {
            let b = bytes[off..<off+4]
            return le
                ? b.enumerated().reduce(0) { $0 | UInt32($1.element) << ($1.offset * 8) }
                : b.enumerated().reduce(0) { $0 | UInt32($1.element) << ((3 - $1.offset) * 8) }
        }

        // Read IEEE 754 Double at offset
        func f64(_ off: Int) -> Double {
            let b = Array(bytes[off..<off+8])
            var bits: UInt64 = 0
            if le { for i in 0..<8 { bits |= UInt64(b[i]) << (i * 8) } }
            else  { for i in 0..<8 { bits |= UInt64(b[i]) << ((7-i) * 8) } }
            return Double(bitPattern: bits)
        }

        let geomType = u32(1)
        let hasSRID  = (geomType & 0x20000000) != 0
        let coordOff = 1 + 4 + (hasSRID ? 4 : 0)   // endian + type + optional SRID

        guard bytes.count >= coordOff + 16 else { return nil }
        return (f64(coordOff), f64(coordOff + 8))   // (longitude, latitude)
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
