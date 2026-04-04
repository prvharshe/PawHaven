// ReviewPublishStep.swift
// PawHaven — AddPet Step 4

import SwiftUI

struct ReviewPublishStep: View {
    @Bindable var vm: AddPetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Almost There!")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Add a location and review before publishing.")
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // City field — geocoded to city-centre on publish (privacy safe)
                PHTextField(
                    label: "City *",
                    placeholder: "e.g. Mumbai",
                    text: $vm.city
                )

                Divider()

                // Preview card
                Text("Preview")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                previewCard

                // Summary
                summarySection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover photo
            Group {
                if let first = vm.selectedImages.first {
                    Image(uiImage: first)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.phBorder
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16/9, contentMode: .fit)
            .clipped()
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(vm.name.isEmpty ? "Pet Name" : vm.name)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                    Spacer()
                    Text(vm.species.emoji)
                        .font(.title3)
                }

                HStack(spacing: 6) {
                    if !vm.breed.isEmpty {
                        Text(vm.breed)
                            .font(.subheadline)
                            .foregroundStyle(Color.phTextSecondary)
                        Text("·")
                            .foregroundStyle(Color.phTextSecondary)
                    }
                    Text(ageLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)
                    Spacer()
                    if !vm.city.isEmpty {
                        Label(vm.city, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(Color.phTextSecondary)
                    }
                }

                HStack(spacing: 6) {
                    if vm.vaccinated { PHTag(text: "Vaccinated", type: .health) }
                    if vm.neutered   { PHTag(text: "Neutered",   type: .health) }
                    PHTag(text: vm.size.displayName, type: .neutral)
                }
            }
            .padding(12)
            .background(Color.phSurface)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 16, bottomTrailingRadius: 16))
        }
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(spacing: 0) {
            row(label: "Photos",  value: "\(vm.selectedImages.count) selected")
            Divider()
            row(label: "Species", value: "\(vm.species.emoji) \(vm.species.displayName)")
            Divider()
            row(label: "Gender",  value: vm.gender.displayName)
            Divider()
            row(label: "Vaccinated", value: vm.vaccinated ? "Yes" : "No")
            Divider()
            row(label: "Neutered",   value: vm.neutered   ? "Yes" : "No")
            if !vm.behaviorTags.isEmpty {
                Divider()
                row(label: "Tags", value: vm.behaviorTags.sorted().joined(separator: ", "))
            }
        }
        .background(Color.phSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phBorder, lineWidth: 1))
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.phTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var ageLabel: String {
        let m = vm.ageMonths
        if m < 12 { return "\(m) mo" }
        let y = m / 12
        return "\(y) yr\(y == 1 ? "" : "s")"
    }
}
