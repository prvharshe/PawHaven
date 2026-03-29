// BasicInfoStep.swift
// PawHaven — AddPet Step 2

import SwiftUI

struct BasicInfoStep: View {
    @Bindable var vm: AddPetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Basic Info")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Tell adopters about this animal.")
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)
                }
                .padding(.top, 8)

                // Name
                PHTextField(
                    label: "Pet Name *",
                    placeholder: "e.g. Bella",
                    text: $vm.name
                )

                // Species
                VStack(alignment: .leading, spacing: 6) {
                    Text("Species *")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.phTextSecondary)

                    HStack(spacing: 10) {
                        ForEach(PetSpecies.allCases, id: \.self) { s in
                            Button {
                                vm.species = s
                            } label: {
                                VStack(spacing: 4) {
                                    Text(s.emoji)
                                        .font(.title2)
                                    Text(s.displayName)
                                        .font(.caption)
                                        .fontWeight(vm.species == s ? .semibold : .regular)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(vm.species == s ? Color.phPrimary.opacity(0.1) : Color.phSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(vm.species == s ? Color.phPrimary : Color.phBorder, lineWidth: vm.species == s ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(response: 0.2), value: vm.species)
                        }
                    }
                }

                // Breed
                PHTextField(
                    label: "Breed (optional)",
                    placeholder: "e.g. Golden Retriever",
                    text: $vm.breed
                )

                // Age slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Age")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.phTextSecondary)
                        Spacer()
                        Text(ageLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.phPrimary)
                    }
                    Slider(value: Binding(
                        get: { Double(vm.ageMonths) },
                        set: { vm.ageMonths = Int($0) }
                    ), in: 1...180, step: 1)
                    .tint(Color.phPrimary)
                }

                // Size
                VStack(alignment: .leading, spacing: 6) {
                    Text("Size")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.phTextSecondary)
                    Picker("Size", selection: $vm.size) {
                        ForEach(PetSize.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Gender
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gender")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.phTextSecondary)
                    Picker("Gender", selection: $vm.gender) {
                        ForEach(PetGender.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    private var ageLabel: String {
        let m = vm.ageMonths
        if m < 12 { return "\(m) month\(m == 1 ? "" : "s")" }
        let y = m / 12
        let rem = m % 12
        var str = "\(y) year\(y == 1 ? "" : "s")"
        if rem > 0 { str += " \(rem)mo" }
        return str
    }
}
