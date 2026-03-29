// MainTabView.swift
// PawHaven

import SwiftUI

enum PHTab: Int, CaseIterable {
    case home, map, addPet, messages, profile
}

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var selectedTab: PHTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Discover", systemImage: "pawprint.fill", value: PHTab.home) {
                HomeView()
            }

            Tab("Map", systemImage: "map.fill", value: PHTab.map) {
                MapPlaceholderView()
            }

            // Centre "Add" tab
            Tab("", systemImage: "plus.circle.fill", value: PHTab.addPet) {
                AddPetPlaceholderView()
            }

            Tab("Messages", systemImage: "bubble.left.and.bubble.right.fill", value: PHTab.messages) {
                MessagesPlaceholderView()
            }

            Tab("Profile", systemImage: "person.fill", value: PHTab.profile) {
                ProfilePlaceholderView()
            }
        }
        .tint(Color.phPrimary)
    }
}

// MARK: - Phase 2/3 Placeholder Screens

struct MapPlaceholderView: View {
    var body: some View {
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

struct AddPetPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.phAccent.opacity(0.7))
            Text("Add a Pet")
                .font(.title2.bold())
            Text("List an animal in your care.\nComing in Phase 2.")
                .font(.subheadline)
                .foregroundStyle(Color.phTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phBackground)
    }
}

struct MessagesPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.phPrimary.opacity(0.5))
            Text("Messages")
                .font(.title2.bold())
            Text("Chat with fosters and adopters.\nComing in Phase 2.")
                .font(.subheadline)
                .foregroundStyle(Color.phTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phBackground)
        .navigationTitle("Messages")
    }
}

struct ProfilePlaceholderView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.phPrimary.opacity(0.5))

                Text("Your Profile")
                    .font(.title2.bold())

                if let id = authVM.currentUserId {
                    Text("User ID: \(id.uuidString.prefix(8))...")
                        .font(.caption)
                        .foregroundStyle(Color.phTextSecondary)
                }

                PHButton(title: "Sign Out", style: .destructive, isFullWidth: false) {
                    Task { await authVM.signOut() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.phBackground)
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthViewModel())
}
