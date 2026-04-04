// ProfileView.swift
// PawHaven

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm            = ProfileViewModel()
    @State private var showEdit           = false
    @State private var showAddPet         = false
    @State private var showSaved          = false
    @State private var showSignOutConfirm = false
    @State private var petToDelete:  Pet? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.phBackground.ignoresSafeArea()

                if vm.isLoading && vm.profile == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    profileContent
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showEdit) {
                EditProfileView(vm: vm)
                    .environment(authVM)
            }
            .sheet(isPresented: $showAddPet) {
                AddPetView()
                    .environment(authVM)
                    .onDisappear {
                        // Refresh my pets after adding one
                        if let userId = authVM.currentUserId {
                            Task { await vm.load(userId: userId) }
                        }
                    }
            }
            .sheet(isPresented: $showSaved) {
                SavedPetsView()
                    .environment(authVM)
            }
            .confirmationDialog("Are you sure?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    Task { await authVM.signOut() }
                }
            }
            .alert("Delete Pet?", isPresented: .init(
                get: { petToDelete != nil },
                set: { if !$0 { petToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    guard let pet = petToDelete, let userId = authVM.currentUserId else { return }
                    Task { await vm.deletePet(pet, userId: userId) }
                    petToDelete = nil
                }
                Button("Cancel", role: .cancel) { petToDelete = nil }
            } message: {
                Text("This will permanently remove \(petToDelete?.name ?? "this pet") from PawHaven.")
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
            .refreshable {
                guard let userId = authVM.currentUserId else { return }
                await vm.load(userId: userId)
            }
        }
    }

    // MARK: - Main Content

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                if vm.profile?.role == .foster || vm.profile?.role == .both {
                    fosterSection
                }

                settingsSection
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AvatarView(
                    url:      vm.profile?.avatarUrl,
                    size:     72,
                    initials: vm.profile?.initials ?? "?"
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(vm.profile?.displayName ?? "Loading...")
                            .font(.system(.title3, weight: .bold))

                        if vm.profile?.verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.phPrimary)
                        }
                    }

                    if let city = vm.profile?.city {
                        Label(city, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(Color.phTextSecondary)
                    }

                    PHTag(
                        text: vm.profile?.role.shortName ?? "",
                        type: .behavior
                    )
                }

                Spacer()
            }

            if let bio = vm.profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(Color.phTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Stats row
            HStack(spacing: 0) {
                statBox(
                    value: "\(vm.myPets.count)",
                    label: "Listed"
                )
                Divider().frame(height: 30)
                statBox(
                    value: "\(vm.myPets.filter { $0.status == .adopted }.count)",
                    label: "Adopted"
                )
                Divider().frame(height: 30)
                statBox(
                    value: "\(vm.myPets.filter { $0.status == .available }.count)",
                    label: "Available"
                )
            }
            .background(Color.phSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.phBorder, lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, weight: .bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.phTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Foster Section

    private var fosterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Availability toggle
            if let profile = vm.profile {
                availabilityToggle(profile: profile)
                    .padding(.horizontal, 20)
            }

            // My Pets header
            HStack {
                Text("My Pets")
                    .font(.headline)
                Spacer()
                Button {
                    showAddPet = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.phPrimary)
                }
            }
            .padding(.horizontal, 20)

            if vm.myPets.isEmpty {
                EmptyStateView(
                    systemImage: "pawprint",
                    title: "No pets listed yet",
                    subtitle: "Add animals in your care to find them a home.",
                    ctaTitle: "Add First Pet",
                    ctaAction: { showAddPet = true }
                )
                .frame(height: 220)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(vm.myPets) { pet in
                        NavigationLink(destination: PetDetailView(petId: pet.id)) {
                            myPetCard(pet)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if pet.status == .available {
                                Button("Mark as Adopted", systemImage: "checkmark.circle.fill") {
                                    guard let userId = authVM.currentUserId else { return }
                                    Task { await vm.updatePetStatus(pet, status: .adopted, userId: userId) }
                                }
                                Button("Mark as Pending", systemImage: "clock.fill") {
                                    guard let userId = authVM.currentUserId else { return }
                                    Task { await vm.updatePetStatus(pet, status: .pending, userId: userId) }
                                }
                            } else {
                                Button("Mark as Available", systemImage: "arrow.uturn.backward") {
                                    guard let userId = authVM.currentUserId else { return }
                                    Task { await vm.updatePetStatus(pet, status: .available, userId: userId) }
                                }
                            }
                            Divider()
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                petToDelete = pet
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Divider()
                .padding(.horizontal, 20)
                .padding(.top, 8)
        }
    }

    // MARK: - Availability Toggle

    private func availabilityToggle(profile: UserProfile) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(profile.availableForIntake ? Color.phSuccess.opacity(0.15) : Color.phBorder.opacity(0.4))
                    .frame(width: 44, height: 44)
                Image(systemName: profile.availableForIntake ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.title3)
                    .foregroundStyle(profile.availableForIntake ? Color.phSuccess : Color.phTextSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Available for Emergency Intake")
                    .font(.system(.subheadline, weight: .semibold))
                Text(profile.availableForIntake
                     ? "You're visible to rescuers looking for foster homes."
                     : "Toggle on when you can take in an injured animal.")
                    .font(.caption)
                    .foregroundStyle(Color.phTextSecondary)
            }

            Spacer()

            Toggle("", isOn: .init(
                get: { profile.availableForIntake },
                set: { _ in
                    guard let userId = authVM.currentUserId else { return }
                    Task { await vm.toggleAvailability(userId: userId) }
                }
            ))
            .labelsHidden()
            .tint(Color.phPrimary)
        }
        .padding(14)
        .background(Color.phSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(profile.availableForIntake ? Color.phSuccess.opacity(0.4) : Color.phBorder, lineWidth: 1)
        )
        .animation(.spring(response: 0.3), value: profile.availableForIntake)
    }

    // MARK: - My Pet Mini Card

    private func myPetCard(_ pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PHAsyncImage(url: pet.coverPhoto?.supabaseThumbnail(width: 300, quality: 70))
                .aspectRatio(1, contentMode: .fit)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.system(.subheadline, weight: .semibold))
                    .lineLimit(1)

                statusBadge(pet.status)
            }
            .padding(8)
            .background(Color.phSurface)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12))
        }
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func statusBadge(_ status: PetStatus) -> some View {
        let (label, type): (String, PHTagType) = switch status {
        case .available: ("Available", .health)
        case .pending:   ("Pending",   .status)
        case .adopted:   ("Adopted",   .behavior)
        }
        return PHTag(text: label, type: type)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.phTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                settingsRow(icon: "heart.fill", label: "Saved Pets") {
                    showSaved = true
                }
                Divider().padding(.leading, 52)
                settingsRow(icon: "bell", label: "Notifications", action: {})
                Divider().padding(.leading, 52)
                settingsRow(icon: "lock.shield", label: "Privacy & Safety", action: {})
                Divider().padding(.leading, 52)
                settingsRow(icon: "questionmark.circle", label: "Help & Feedback", action: {})
            }
            .background(Color.phSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phBorder, lineWidth: 1))
            .padding(.horizontal, 20)

            PHButton(title: "Sign Out", style: .destructive) {
                showSignOutConfirm = true
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .padding(.top, 20)
    }

    private func settingsRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.phPrimary)
                    .frame(width: 24)
                Text(label)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.phTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showEdit = true
            } label: {
                Text("Edit")
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthViewModel())
}
