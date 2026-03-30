// MessagesListViewModel.swift
// PawHaven

import SwiftUI
import Observation

@Observable
@MainActor
final class MessagesListViewModel {
    var threads:      [ChatThread] = []
    var isLoading:    Bool         = false
    var errorMessage: String?      = nil

    private let chatService:    ChatService
    private let petService:     PetService
    private let profileService: ProfileService

    init(
        chatService:    ChatService    = ChatService(),
        petService:     PetService     = PetService(),
        profileService: ProfileService = ProfileService()
    ) {
        self.chatService    = chatService
        self.petService     = petService
        self.profileService = profileService
    }

    func load(userId: UUID) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var raw = try await chatService.fetchThreads(userId: userId)

            // Enrich each thread with pet + other user profile
            await withTaskGroup(of: (Int, Pet?, UserProfile?).self) { group in
                for (i, thread) in raw.enumerated() {
                    group.addTask { [weak self] in
                        guard let self else { return (i, nil, nil) }
                        let pet: Pet?
                        if let pid = thread.petId {
                            pet = try? await self.petService.fetchPet(id: pid)
                        } else {
                            pet = nil
                        }
                        let profile = try? await self.profileService.fetchProfile(userId: thread.otherUserId)
                        return (i, pet, profile)
                    }
                }
                for await (i, pet, profile) in group {
                    raw[i].pet       = pet
                    raw[i].otherUser = profile
                }
            }

            threads = raw
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
