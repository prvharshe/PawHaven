// PetService.swift
// PawHaven
//
// All database operations for pets. Joins foster profile on every fetch
// so views never need a second round-trip.

import Foundation
import Supabase

final class PetService {
    private let client: SupabaseClient

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Fetch Feed

    func fetchAvailablePets(page: Int = 0, filters: PetFilters = PetFilters()) async throws -> [Pet] {
        // All .eq() filters must come before .order() / .range() —
        // those return PostgrestTransformBuilder which has no filter methods.
        var query = client
            .from("pets")
            .select("*, foster:users!pets_foster_id_fkey(*)")
            .eq("status", value: PetStatus.available.rawValue)

        if let species = filters.species {
            query = query.eq("species", value: species.rawValue)
        }
        if let size = filters.size {
            query = query.eq("size", value: size.rawValue)
        }

        return try await query
            .order("created_at", ascending: false)
            .range(from: page * 20, to: (page + 1) * 20 - 1)
            .execute()
            .value
    }

    // MARK: - Fetch Single Pet

    func fetchPet(id: UUID) async throws -> Pet {
        try await client
            .from("pets")
            .select("*, foster:users!pets_foster_id_fkey(*)")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    // MARK: - Save / Unsave

    func savePet(petId: UUID, userId: UUID) async throws {
        try await client
            .from("saved_pets")
            .upsert(["user_id": userId.uuidString, "pet_id": petId.uuidString])
            .execute()
    }

    func unsavePet(petId: UUID, userId: UUID) async throws {
        try await client
            .from("saved_pets")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("pet_id", value: petId.uuidString)
            .execute()
    }

    func fetchSavedPetIds(userId: UUID) async throws -> Set<UUID> {
        struct SavedRow: Decodable { let petId: UUID; enum CodingKeys: String, CodingKey { case petId = "pet_id" } }
        let rows: [SavedRow] = try await client
            .from("saved_pets")
            .select("pet_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return Set(rows.map(\.petId))
    }

    // MARK: - Foster: My Pets

    func fetchMyPets(fosterId: UUID) async throws -> [Pet] {
        try await client
            .from("pets")
            .select()
            .eq("foster_id", value: fosterId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Create Pet

    func createPet(_ draft: PetInsert) async throws -> Pet {
        try await client
            .from("pets")
            .insert(draft)
            .select("*, foster:users!pets_foster_id_fkey(*)")
            .single()
            .execute()
            .value
    }

    // MARK: - Update Status

    func updatePetStatus(_ id: UUID, status: PetStatus) async throws {
        try await client
            .from("pets")
            .update(["status": status.rawValue])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Delete Pet

    func deletePet(_ id: UUID) async throws {
        try await client
            .from("pets")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Insert DTO

struct PetInsert: Encodable {
    let id: UUID
    let fosterId: UUID
    let name: String
    let species: String
    let breed: String?
    let ageMonths: Int?
    let size: String?
    let gender: String
    let description: String?
    let healthNotes: String?
    let behaviorNotes: String?
    let vaccinated: Bool
    let neutered: Bool
    let status: String
    let city: String?
    let photos: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case fosterId      = "foster_id"
        case name, species, breed, gender, description, vaccinated, neutered, status, city, photos
        case ageMonths     = "age_months"
        case size
        case healthNotes   = "health_notes"
        case behaviorNotes = "behavior_notes"
    }
}
