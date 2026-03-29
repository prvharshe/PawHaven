// AddPetViewModel.swift
// PawHaven
//
// Owns all form state across the 4-step Add Pet flow.
// Call publish() on step 4 to upload images then insert the pet row.

import SwiftUI
import Observation
import PhotosUI

@Observable
@MainActor
final class AddPetViewModel {

    // MARK: - Step
    var currentStep: Int = 0          // 0…3
    let totalSteps   = 4

    // MARK: - Step 1: Photos
    var selectedItems:  [PhotosPickerItem] = []
    var selectedImages: [UIImage]          = []

    // MARK: - Step 2: Basic Info
    var name:      String    = ""
    var species:   PetSpecies = .dog
    var breed:     String    = ""
    var ageMonths: Int       = 12
    var size:      PetSize   = .medium
    var gender:    PetGender = .unknown

    // MARK: - Step 3: Health & Behaviour
    var vaccinated:    Bool   = false
    var neutered:      Bool   = false
    var healthNotes:   String = ""
    var behaviorNotes: String = ""
    var behaviorTags:  Set<String> = []

    // MARK: - Step 4: Location & Review
    var city: String = ""

    // MARK: - Publish state
    var isPublishing:   Bool    = false
    var publishError:   String? = nil
    var publishedPet:   Pet?    = nil   // set on success → triggers dismiss

    // MARK: - Services
    private let petService:     PetService
    private let storageService: StorageService

    init(petService: PetService = PetService(), storageService: StorageService = StorageService()) {
        self.petService     = petService
        self.storageService = storageService
    }

    // MARK: - Navigation

    var canAdvance: Bool {
        switch currentStep {
        case 0: return !selectedImages.isEmpty
        case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return true
        case 3: return !city.trimmingCharacters(in: .whitespaces).isEmpty
        default: return false
        }
    }

    func next() { if currentStep < totalSteps - 1 { currentStep += 1 } }
    func back() { if currentStep > 0 { currentStep -= 1 } }

    // MARK: - Photo Loading

    func loadImages(from items: [PhotosPickerItem]) async {
        var loaded: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(image)
            }
        }
        selectedImages = loaded
    }

    // MARK: - Publish

    func publish(fosterId: UUID) async {
        guard canAdvance else { return }
        isPublishing = true
        publishError = nil
        defer { isPublishing = false }

        do {
            let petId = UUID()

            // 1. Upload photos concurrently
            let photoURLs = try await storageService.uploadPetPhotos(selectedImages, petId: petId)

            // 2. Insert pet row
            let draft = PetInsert(
                id:            petId,
                fosterId:      fosterId,
                name:          name.trimmingCharacters(in: .whitespaces),
                species:       species.rawValue,
                breed:         breed.isEmpty ? nil : breed,
                ageMonths:     ageMonths,
                size:          size.rawValue,
                gender:        gender.rawValue,
                description:   nil,
                healthNotes:   healthNotes.isEmpty ? nil : healthNotes,
                behaviorNotes: buildBehaviorNotes(),
                vaccinated:    vaccinated,
                neutered:      neutered,
                status:        PetStatus.available.rawValue,
                city:          city.trimmingCharacters(in: .whitespaces),
                photos:        photoURLs
            )
            publishedPet = try await petService.createPet(draft)
        } catch {
            publishError = error.localizedDescription
        }
    }

    private func buildBehaviorNotes() -> String? {
        var parts: [String] = []
        if !behaviorTags.isEmpty {
            parts.append(behaviorTags.sorted().joined(separator: ", "))
        }
        if !behaviorNotes.isEmpty {
            parts.append(behaviorNotes)
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }
}

// MARK: - Behaviour tag presets
extension AddPetViewModel {
    static let behaviorOptions = [
        "Good with kids", "Good with dogs", "Good with cats",
        "House trained", "Leash trained", "Loves cuddles",
        "Active", "Calm", "Playful", "Independent"
    ]
}
