// EditProfileView.swift
// PawHaven

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    let vm: ProfileViewModel

    @State private var displayName: String
    @State private var bio:         String
    @State private var city:        String
    @State private var avatarItem:  PhotosPickerItem? = nil
    @State private var avatarImage: UIImage?          = nil

    init(vm: ProfileViewModel) {
        self.vm      = vm
        _displayName = State(initialValue: vm.profile?.displayName ?? "")
        _bio         = State(initialValue: vm.profile?.bio         ?? "")
        _city        = State(initialValue: vm.profile?.city        ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Avatar picker
                    VStack(spacing: 10) {
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let avatarImage {
                                        Image(uiImage: avatarImage)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        AvatarView(
                                            url:      vm.profile?.avatarUrl,
                                            size:     88,
                                            initials: vm.profile?.initials ?? "?"
                                        )
                                    }
                                }
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.phBorder, lineWidth: 1))

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(Color.phPrimary)
                                    .clipShape(Circle())
                            }
                        }
                        .onChange(of: avatarItem) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let img  = UIImage(data: data) {
                                    avatarImage = img
                                }
                            }
                        }
                        Text("Tap to change photo")
                            .font(.caption)
                            .foregroundStyle(Color.phTextSecondary)
                    }
                    .padding(.top, 8)

                    // MARK: - Fields
                    VStack(spacing: 16) {
                        PHTextField(
                            label: "Display Name",
                            placeholder: "Your name",
                            text: $displayName
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bio")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.phTextSecondary)
                            TextEditor(text: $bio)
                                .frame(minHeight: 80)
                                .padding(10)
                                .background(Color.phSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.phBorder, lineWidth: 1))
                                .overlay(alignment: .topLeading) {
                                    if bio.isEmpty {
                                        Text("Tell adopters a little about yourself...")
                                            .font(.body)
                                            .foregroundStyle(Color.phTextSecondary.opacity(0.6))
                                            .padding(14)
                                            .allowsHitTesting(false)
                                    }
                                }
                        }

                        PHTextField(
                            label: "City",
                            placeholder: "e.g. Mumbai",
                            text: $city
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color.phBackground.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let userId = authVM.currentUserId else { return }
                        Task {
                            await vm.saveProfile(
                                userId:      userId,
                                displayName: displayName,
                                bio:         bio,
                                city:        city,
                                avatarImage: avatarImage
                            )
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSaving)
                }
            }
            .overlay {
                if vm.isSaving {
                    ZStack {
                        Color.black.opacity(0.15).ignoresSafeArea()
                        ProgressView("Saving...")
                            .padding(20)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
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
}
