// PetDetailViewModel.swift
// PawHaven

import SwiftUI
import Observation

@Observable
@MainActor
final class PetDetailViewModel {
    var pet:          Pet?     = nil
    var isLoading:    Bool     = false
    var errorMessage: String?  = nil
    var isSaved:      Bool     = false

    private let petService: PetService

    init(petService: PetService = PetService()) {
        self.petService = petService
    }

    func load(petId: UUID) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            pet = try await petService.fetchPet(id: petId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSave(userId: UUID) async {
        guard let pet else { return }
        isSaved.toggle() // optimistic
        do {
            if isSaved {
                try await petService.savePet(petId: pet.id, userId: userId)
            } else {
                try await petService.unsavePet(petId: pet.id, userId: userId)
            }
        } catch {
            isSaved.toggle() // revert
        }
    }
}
