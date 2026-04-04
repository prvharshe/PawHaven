// FilterSheetView.swift
// PawHaven
//
// Full-featured filter sheet for the Home feed.
// Works on a local draft so the user can Reset / Apply atomically.

import SwiftUI

struct FilterSheetView: View {
    @Binding var filters: PetFilters
    @Environment(\.dismiss) private var dismiss

    // Local draft — applied only when user taps "Apply"
    @State private var draft: PetFilters

    init(filters: Binding<PetFilters>) {
        _filters = filters
        _draft   = State(initialValue: filters.wrappedValue)
    }

    var activeCount: Int {
        [
            draft.species    != nil,
            draft.size       != nil,
            draft.gender     != nil,
            draft.vaccinated != nil,
            draft.neutered   != nil,
        ].filter { $0 }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.phBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        speciesSection
                        Divider().padding(.horizontal, 20)
                        sizeSection
                        Divider().padding(.horizontal, 20)
                        genderSection
                        Divider().padding(.horizontal, 20)
                        healthSection
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 100)
                }

                // Sticky Apply button
                VStack {
                    Spacer()
                    applyBar
                }
            }
            .navigationTitle(activeCount > 0 ? "Filters (\(activeCount))" : "Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        withAnimation { draft = PetFilters() }
                    }
                    .foregroundStyle(Color.phDestructive)
                    .disabled(draft == PetFilters())
                }
            }
        }
    }

    // MARK: - Species

    private var speciesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Animal Type")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(PetSpecies.allCases, id: \.self) { species in
                    filterChip(
                        label: "\(species.emoji) \(species.displayName)",
                        isSelected: draft.species == species
                    ) {
                        draft.species = draft.species == species ? nil : species
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Size

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Size")

            HStack(spacing: 10) {
                ForEach(PetSize.allCases, id: \.self) { size in
                    filterChip(label: size.displayName, isSelected: draft.size == size, flex: true) {
                        draft.size = draft.size == size ? nil : size
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Gender

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Gender")

            HStack(spacing: 10) {
                ForEach([PetGender.male, .female, .unknown], id: \.self) { gender in
                    filterChip(label: gender.displayName, isSelected: draft.gender == gender, flex: true) {
                        draft.gender = draft.gender == gender ? nil : gender
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Health

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Health")

            VStack(spacing: 0) {
                toggleRow(
                    icon: "cross.case.fill",
                    label: "Vaccinated",
                    isOn: Binding(
                        get: { draft.vaccinated == true },
                        set: { draft.vaccinated = $0 ? true : nil }
                    )
                )
                Divider().padding(.leading, 52)
                toggleRow(
                    icon: "scissors",
                    label: "Neutered / Spayed",
                    isOn: Binding(
                        get: { draft.neutered == true },
                        set: { draft.neutered = $0 ? true : nil }
                    )
                )
            }
            .background(Color.phSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phBorder, lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Apply Bar

    private var applyBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                PHButton(title: "Show Results", style: .primary) {
                    filters = draft
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.phBackground)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.phTextSecondary)
    }

    private func filterChip(
        label: String,
        isSelected: Bool,
        flex: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: flex ? .infinity : nil)
                .padding(.horizontal, flex ? 0 : 14)
                .padding(.vertical, 10)
                .background(isSelected ? Color.phPrimary : Color.phSurface)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Color.phBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
    }

    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.phPrimary)
                .frame(width: 24)

            Text(label)
                .font(.body)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.phPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
