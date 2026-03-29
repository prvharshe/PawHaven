// PhotoPickerStep.swift
// PawHaven — AddPet Step 1

import SwiftUI
import PhotosUI

struct PhotoPickerStep: View {
    @Bindable var vm: AddPetViewModel   // @Bindable works with @Observable

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instruction
                VStack(spacing: 6) {
                    Text("Add Photos")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Add up to 8 photos. The first one is the cover.")
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // Photo picker button
                PhotosPicker(
                    selection: $vm.selectedItems,
                    maxSelectionCount: 8,
                    matching: .images
                ) {
                    Label("Choose Photos", systemImage: "photo.on.rectangle.angled")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(Color.phPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.phPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phPrimary.opacity(0.3), lineWidth: 1))
                }
                .onChange(of: vm.selectedItems) { _, items in
                    Task { await vm.loadImages(from: items) }
                }

                // Grid preview
                if !vm.selectedImages.isEmpty {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(vm.selectedImages.enumerated()), id: \.offset) { i, image in
                            ZStack(alignment: .topLeading) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                if i == 0 {
                                    Text("Cover")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.phPrimary)
                                        .clipShape(Capsule())
                                        .padding(6)
                                }
                            }
                        }
                    }
                }

                if vm.selectedImages.isEmpty {
                    // Empty state placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.phBorder.opacity(0.4))
                        .frame(height: 200)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.phTextSecondary)
                                Text("No photos selected")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.phTextSecondary)
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)   // space for bottom bar
        }
    }
}
