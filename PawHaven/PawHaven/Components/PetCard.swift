// PetCard.swift
// PawHaven
//
// Card used in the home feed. Tapping navigates to PetDetailView via
// NavigationStack's navigationDestination(for: Pet.self).

import SwiftUI

struct PetCard: View {
    let pet: Pet
    var namespace: Namespace.ID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Photo
            ZStack(alignment: .topTrailing) {
                PHAsyncImage(url: pet.coverPhoto?.supabaseThumbnail(width: 600, quality: 75))
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipped()

                // "New" badge
                if pet.isNew {
                    PHTag(text: "New", type: .status)
                        .padding(10)
                }
            }
            .clipShape(
                UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
            )

            // MARK: - Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(pet.name)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Text(pet.species.emoji)
                        .font(.title3)
                }

                HStack(spacing: 6) {
                    if let breed = pet.breed {
                        Text(breed)
                            .font(.subheadline)
                            .foregroundStyle(Color.phTextSecondary)
                    }

                    if pet.breed != nil {
                        Text("·")
                            .foregroundStyle(Color.phTextSecondary)
                    }

                    Text(pet.ageDisplay)
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)

                    Spacer()

                    if let city = pet.city {
                        Label(city, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(Color.phTextSecondary)
                            .lineLimit(1)
                    }
                }

                // Health tags
                HStack(spacing: 6) {
                    if pet.vaccinated {
                        PHTag(text: "Vaccinated", type: .health, icon: "checkmark.shield.fill")
                    }
                    if pet.neutered {
                        PHTag(text: "Neutered", type: .health)
                    }
                    if let size = pet.size {
                        PHTag(text: size.displayName, type: .neutral)
                    }
                }
                .padding(.top, 2)
            }
            .padding(12)
            .background(Color.phSurface)
            .clipShape(
                UnevenRoundedRectangle(bottomLeadingRadius: 16, bottomTrailingRadius: 16)
            )
        }
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .if(namespace != nil) { view in
            view.matchedTransitionSource(id: pet.id, in: namespace!)
        }
    }
}

// MARK: - Conditional modifier helper
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

#Preview {
    let pet = Pet(
        id: UUID(),
        fosterId: UUID(),
        name: "Bella",
        species: .dog,
        breed: "Golden Retriever",
        ageMonths: 14,
        size: .medium,
        gender: .female,
        description: "Friendly and loves cuddles.",
        healthNotes: nil,
        behaviorNotes: nil,
        vaccinated: true,
        neutered: true,
        status: .available,
        urgent: false,
        city: "Mumbai",
        photos: [],
        createdAt: .now
    )
    PetCard(pet: pet)
        .padding()
        .background(Color.phBackground)
}
