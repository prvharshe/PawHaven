// ProfileViewModel.swift
// PawHaven

import SwiftUI
import Observation

@Observable
@MainActor
final class ProfileViewModel {

    // MARK: - State
    var profile:          UserProfile? = nil
    var myPets:           [Pet]        = []
    var isLoading:        Bool         = false
    var isSaving:         Bool         = false
    var errorMessage:     String?      = nil
    var successMessage:   String?      = nil

    // MARK: - Services
    private let profileService: ProfileService
    private let petService:     PetService
    private let storageService: StorageService

    init(
        profileService: ProfileService = ProfileService(),
        petService:     PetService     = PetService(),
        storageService: StorageService = StorageService()
    ) {
        self.profileService = profileService
        self.petService     = petService
        self.storageService = storageService
    }

    // MARK: - Load

    func load(userId: UUID) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let profileFetch = profileService.fetchProfile(userId: userId)
            async let petsFetch    = petService.fetchMyPets(fosterId: userId)
            let (p, pets) = try await (profileFetch, petsFetch)
            profile = p
            myPets  = pets
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Availability Toggle

    func toggleAvailability(userId: UUID) async {
        guard var p = profile else { return }
        p.availableForIntake.toggle()
        profile = p   // optimistic
        do {
            try await profileService.setAvailableForIntake(p.availableForIntake, userId: userId)
        } catch {
            p.availableForIntake.toggle()
            profile      = p   // revert
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update Pet Status

    func updatePetStatus(_ pet: Pet, status: PetStatus, userId: UUID) async {
        do {
            try await petService.updatePetStatus(pet.id, status: status)
            await load(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Pet

    func deletePet(_ pet: Pet, userId: UUID) async {
        do {
            try await petService.deletePet(pet.id)
            myPets.removeAll { $0.id == pet.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save Profile Edits

    func saveProfile(
        userId:      UUID,
        displayName: String,
        bio:         String,
        city:        String,
        avatarImage: UIImage?
    ) async {
        isSaving     = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            var avatarUrl = profile?.avatarUrl
            if let img = avatarImage {
                avatarUrl = try await storageService.uploadAvatar(img, userId: userId)
            }
            try await profileService.updateProfile(
                userId:      userId,
                displayName: displayName,
                bio:         bio.isEmpty ? nil : bio,
                city:        city.isEmpty ? nil : city,
                avatarUrl:   avatarUrl
            )
            await load(userId: userId)
            successMessage = "Profile updated!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
