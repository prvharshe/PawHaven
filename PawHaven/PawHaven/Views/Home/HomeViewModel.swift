// HomeViewModel.swift
// PawHaven

import SwiftUI
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var pets:         [Pet]       = []
    var isLoading:    Bool        = false
    var isLoadingMore:Bool        = false
    var errorMessage: String?     = nil
    var filters:      PetFilters  = PetFilters()
    var savedPetIds:  Set<UUID>   = []

    private var currentPage      = 0
    private var hasMore          = true

    private let petService: PetService

    init(petService: PetService = PetService()) {
        self.petService = petService
    }

    // MARK: - Load

    func loadInitial(userId: UUID?) async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil
        currentPage  = 0
        hasMore      = true
        defer { isLoading = false }

        do {
            async let fetched = petService.fetchAvailablePets(page: 0, filters: filters)
            if let userId {
                async let savedIds = petService.fetchSavedPetIds(userId: userId)
                let (result, saved) = try await (fetched, savedIds)
                pets = result
                savedPetIds = saved
                hasMore = result.count == 20
            } else {
                let result = try await fetched
                pets = result
                savedPetIds = []
                hasMore = result.count == 20
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        currentPage += 1
        do {
            let more = try await petService.fetchAvailablePets(page: currentPage, filters: filters)
            pets.append(contentsOf: more)
            hasMore = more.count == 20
        } catch {
            currentPage -= 1
        }
    }

    func applyFilter(_ newFilters: PetFilters, userId: UUID?) async {
        filters = newFilters
        await loadInitial(userId: userId)
    }

    // MARK: - Save / Unsave

    func toggleSave(pet: Pet, userId: UUID) async {
        let isSaved = savedPetIds.contains(pet.id)
        // Optimistic update
        if isSaved {
            savedPetIds.remove(pet.id)
        } else {
            savedPetIds.insert(pet.id)
        }
        do {
            if isSaved {
                try await petService.unsavePet(petId: pet.id, userId: userId)
            } else {
                try await petService.savePet(petId: pet.id, userId: userId)
            }
        } catch {
            // Revert on failure
            if isSaved { savedPetIds.insert(pet.id) } else { savedPetIds.remove(pet.id) }
        }
    }
}
