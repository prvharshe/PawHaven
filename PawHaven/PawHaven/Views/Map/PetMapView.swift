// PetMapView.swift
// PawHaven
//
// MapKit map showing available pet pins.
// Tap a pin → bottom card previewing the pet → tap card → full PetDetailView.

import SwiftUI
import MapKit

struct PetMapView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm          = PetMapViewModel()
    @State private var selectedPet: Pet? = nil
    @State private var path        = NavigationPath()

    // Start with a wide view of India; snaps to user location once available.
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
            span:   MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)
        )
    )

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                map

                if let pet = selectedPet {
                    petBottomCard(pet)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if vm.isLoading {
                    loadingPill
                } else if !vm.isLoading && vm.petsWithCoordinates.isEmpty {
                    noUrgentPillView
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Needs Help Now")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Pet.self) { pet in
                PetDetailView(petId: pet.id)
            }
            .task { await vm.load() }
            .onChange(of: vm.locationManager.location) { _, loc in
                guard let loc else { return }
                withAnimation(.easeInOut(duration: 1)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: loc.coordinate,
                        span:   MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    ))
                }
            }
            .alert("Error", isPresented: .init(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $cameraPosition, selection: .constant(nil)) {
            // User dot
            UserAnnotation()

            // Pet pins
            ForEach(vm.petsWithCoordinates) { pet in
                Annotation(pet.name, coordinate: pet.coordinate!) {
                    PetMapPin(pet: pet, isSelected: selectedPet?.id == pet.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPet = (selectedPet?.id == pet.id) ? nil : pet
                            }
                        }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onTapGesture {
            withAnimation { selectedPet = nil }
        }
    }

    // MARK: - Pet Bottom Card

    private func petBottomCard(_ pet: Pet) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.phBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            HStack(spacing: 14) {
                // Thumbnail
                PHAsyncImage(url: pet.coverPhoto?.supabaseThumbnail(width: 120, quality: 70))
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(pet.name)
                            .font(.system(.headline, design: .rounded))
                        Text(pet.species.emoji)
                    }
                    if let breed = pet.breed {
                        Text(breed)
                            .font(.subheadline)
                            .foregroundStyle(Color.phTextSecondary)
                    }
                    HStack(spacing: 6) {
                        Text(pet.ageDisplay)
                            .font(.caption)
                            .foregroundStyle(Color.phTextSecondary)
                        if let city = pet.city {
                            Text("·").foregroundStyle(Color.phTextSecondary)
                            Label(city, systemImage: "location.fill")
                                .font(.caption)
                                .foregroundStyle(Color.phTextSecondary)
                        }
                    }
                }

                Spacer()

                // Arrow CTA
                Button {
                    path.append(pet)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.phPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.phSurface)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: -4)
        .padding(.bottom, 0)
    }

    // MARK: - Loading Pill

    private var loadingPill: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
            Text("Looking for animals in need…")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 220)
    }

    private var noUrgentPillView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.phSuccess)
            Text("No animals need urgent help nearby")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 220)
    }
}

// MARK: - Pet Map Pin

struct PetMapPin: View {
    let pet: Pet
    let isSelected: Bool

    var body: some View {
        ZStack {
            // Pulsing ring for urgent pins
            if pet.urgent {
                Circle()
                    .fill(Color.phDestructive.opacity(0.2))
                    .frame(width: isSelected ? 70 : 56, height: isSelected ? 70 : 56)
            }

            Circle()
                .fill(pet.urgent
                      ? (isSelected ? Color.phDestructive : Color(red: 0.95, green: 0.25, blue: 0.25))
                      : (isSelected ? Color.phPrimary : Color.white))
                .frame(width: isSelected ? 52 : 40, height: isSelected ? 52 : 40)
                .shadow(color: (pet.urgent ? Color.phDestructive : Color.black).opacity(0.25),
                        radius: 4, x: 0, y: 2)

            if pet.urgent && !isSelected {
                Text("🆘")
                    .font(.system(size: 20))
            } else {
                Text(pet.species.emoji)
                    .font(.system(size: isSelected ? 26 : 20))
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
