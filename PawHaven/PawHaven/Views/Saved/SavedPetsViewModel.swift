// SavedPetsViewModel.swift
// PawHaven

import SwiftUI
import Observation

@Observable
@MainActor
final class SavedPetsViewModel {
    var pets:         [Pet]   = []
    var isLoading:    Bool    = false
    var errorMessage: String? = nil

    private let petService: PetService

    init(petService: PetService = PetService()) {
        self.petService = petService
    }

    func load(userId: UUID) async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            pets = try await petService.fetchSavedPets(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unsave(pet: Pet, userId: UUID) async {
        // Optimistic removal
        pets.removeAll { $0.id == pet.id }
        do {
            try await petService.unsavePet(petId: pet.id, userId: userId)
        } catch {
            // Revert on failure
            pets.append(pet)
            errorMessage = error.localizedDescription
        }
    }
}
