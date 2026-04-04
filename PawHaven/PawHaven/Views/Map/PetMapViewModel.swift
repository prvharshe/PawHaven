// PetMapViewModel.swift
// PawHaven

import SwiftUI
import MapKit
import Observation

@Observable
@MainActor
final class PetMapViewModel {
    var pets:         [Pet]   = []
    var isLoading:    Bool    = false
    var errorMessage: String? = nil

    // Location
    let locationManager = LocationManager()

    private let petService: PetService

    init(petService: PetService = PetService()) {
        self.petService = petService
    }

    var petsWithCoordinates: [Pet] {
        pets.filter { $0.coordinate != nil }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        locationManager.requestPermissionAndLocation()

        do {
            pets = try await petService.fetchPetsForMap()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
