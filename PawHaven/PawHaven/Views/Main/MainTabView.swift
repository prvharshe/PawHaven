// MainTabView.swift
// PawHaven

import SwiftUI

enum PHTab: Int, CaseIterable {
    case home, map, addPet, messages, profile
}

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var selectedTab: PHTab = .home
    @State private var showAddPet        = false

    var body: some View {
        TabView(selection: $selectedTab) {

            Tab("Discover", systemImage: "pawprint.fill", value: PHTab.home) {
                HomeView()
            }

            Tab("Map", systemImage: "map.fill", value: PHTab.map) {
                MapPlaceholderView()
            }

            // Centre "+" tab — opens AddPetView as a sheet so the tab bar
            // stays visible and we can dismiss easily.
            Tab("Add", systemImage: "plus.circle.fill", value: PHTab.addPet) {
                Color.clear
            }

            Tab("Messages", systemImage: "bubble.left.and.bubble.right.fill", value: PHTab.messages) {
                MessagesListView()
            }

            Tab("Profile", systemImage: "person.fill", value: PHTab.profile) {
                ProfileView()
            }
        }
        .tint(Color.phPrimary)
        // Intercept the "+" tab: don't navigate to it, open a sheet instead.
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .addPet {
                showAddPet  = true
                selectedTab = .home   // snap back so the tab never appears "selected"
            }
        }
        .sheet(isPresented: $showAddPet) {
            AddPetView()
                .environment(authVM)
        }
    }
}

// MARK: - Map Placeholder (Phase 3)

struct MapPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.phPrimary.opacity(0.5))
                Text("Map View")
                    .font(.title2.bold())
                Text("Nearby pets, fosters, and vets.\nComing in Phase 3.")
                    .font(.subheadline)
                    .foregroundStyle(Color.phTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.phBackground)
            .navigationTitle("Map")
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthViewModel())
}
