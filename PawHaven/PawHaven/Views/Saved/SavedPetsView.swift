// SavedPetsView.swift
// PawHaven
//
// Grid of pets the current user has bookmarked.

import SwiftUI

struct SavedPetsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm   = SavedPetsViewModel()
    @State private var path = NavigationPath()

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.phBackground.ignoresSafeArea()

                if vm.isLoading && vm.pets.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.pets.isEmpty && !vm.isLoading {
                    EmptyStateView(
                        systemImage: "heart.slash",
                        title: "No saved pets",
                        subtitle: "Tap the heart on any pet to save them here.",
                        ctaTitle: nil,
                        ctaAction: nil
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(vm.pets) { pet in
                                NavigationLink(value: pet) {
                                    savedPetCard(pet)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Remove from Saved", systemImage: "heart.slash", role: .destructive) {
                                        if let userId = authVM.currentUserId {
                                            Task { await vm.unsave(pet: pet, userId: userId) }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        guard let userId = authVM.currentUserId else { return }
                        await vm.load(userId: userId)
                    }
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Pet.self) { pet in
                PetDetailView(petId: pet.id)
            }
            .alert("Error", isPresented: .init(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .task {
                guard let userId = authVM.currentUserId else { return }
                await vm.load(userId: userId)
            }
        }
    }

    // MARK: - Pet Card

    private func savedPetCard(_ pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PHAsyncImage(url: pet.coverPhoto?.supabaseThumbnail(width: 300, quality: 70))
                .aspectRatio(1, contentMode: .fit)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.phDestructive)
                        .clipShape(Circle())
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.system(.subheadline, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(pet.species.emoji)
                    if let city = pet.city {
                        Text(city)
                            .font(.caption)
                            .foregroundStyle(Color.phTextSecondary)
                            .lineLimit(1)
                    } else {
                        Text(pet.ageDisplay)
                            .font(.caption)
                            .foregroundStyle(Color.phTextSecondary)
                    }
                }
            }
            .padding(10)
            .background(Color.phSurface)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14))
        }
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    SavedPetsView()
        .environment(AuthViewModel())
}
