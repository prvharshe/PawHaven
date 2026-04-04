// HomeView.swift
// PawHaven

import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authVM

    @State private var vm           = HomeViewModel()
    @State private var path         = NavigationPath()
    @State private var showFilters  = false
    @Namespace private var hero

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.phBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        filterChips

                        if vm.isLoading {
                            skeletonList
                        } else if vm.pets.isEmpty {
                            EmptyStateView(
                                systemImage: "pawprint",
                                title: "No pets nearby",
                                subtitle: "Try removing filters or check back soon.",
                                ctaTitle: vm.filters != PetFilters() ? "Clear Filters" : nil,
                                ctaAction: vm.filters != PetFilters() ? {
                                    Task { await vm.applyFilter(PetFilters(), userId: authVM.currentUserId) }
                                } : nil
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(vm.pets) { pet in
                                NavigationLink(value: pet) {
                                    PetCard(pet: pet, namespace: hero)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if pet == vm.pets.last {
                                        Task { await vm.loadMore() }
                                    }
                                }
                            }

                            if vm.isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await vm.loadInitial(userId: authVM.currentUserId)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Label("Filters", systemImage: vm.filters == PetFilters()
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(vm.filters == PetFilters()
                                             ? Color.primary : Color.phPrimary)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheetView(filters: Binding(
                    get: { vm.filters },
                    set: { newFilters in
                        Task { await vm.applyFilter(newFilters, userId: authVM.currentUserId) }
                    }
                ))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: Pet.self) { pet in
                PetDetailView(petId: pet.id)
                    .navigationTransition(.zoom(sourceID: pet.id, in: hero))
            }
            .task {
                await vm.loadInitial(userId: authVM.currentUserId)
            }
            .alert("Error", isPresented: .init(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("Retry") { Task { await vm.loadInitial(userId: authVM.currentUserId) } }
                Button("Dismiss", role: .cancel) { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Species chips
                ForEach(PetSpecies.allCases, id: \.self) { species in
                    let isSelected = vm.filters.species == species
                    Button {
                        let newFilters = PetFilters(
                            species: isSelected ? nil : species,
                            size: vm.filters.size
                        )
                        Task { await vm.applyFilter(newFilters, userId: authVM.currentUserId) }
                    } label: {
                        HStack(spacing: 4) {
                            Text(species.emoji)
                            Text(species.displayName)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.phPrimary : Color.phSurface)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(isSelected ? Color.clear : Color.phBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25), value: isSelected)
                }

                Divider().frame(height: 24)

                // Size chips
                ForEach(PetSize.allCases, id: \.self) { size in
                    let isSelected = vm.filters.size == size
                    Button {
                        let newFilters = PetFilters(
                            species: vm.filters.species,
                            size: isSelected ? nil : size
                        )
                        Task { await vm.applyFilter(newFilters, userId: authVM.currentUserId) }
                    } label: {
                        Text(size.displayName)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.phAccent : Color.phSurface)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? Color.clear : Color.phBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25), value: isSelected)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Skeleton
    private var skeletonList: some View {
        VStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                PetCardSkeleton()
                    .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AuthViewModel())
}
