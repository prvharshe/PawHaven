// HealthBehaviorStep.swift
// PawHaven — AddPet Step 3

import SwiftUI

struct HealthBehaviorStep: View {
    @Bindable var vm: AddPetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Health & Behaviour")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Help adopters understand this animal's needs.")
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // Health toggles
                VStack(spacing: 0) {
                    Toggle(isOn: $vm.vaccinated) {
                        Label("Vaccinated", systemImage: "checkmark.shield.fill")
                    }
                    .tint(Color.phPrimary)
                    .padding()

                    Divider().padding(.leading, 52)

                    Toggle(isOn: $vm.neutered) {
                        Label("Neutered / Spayed", systemImage: "scissors")
                    }
                    .tint(Color.phPrimary)
                    .padding()
                }
                .background(Color.phSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phBorder, lineWidth: 1))

                // Health notes
                VStack(alignment: .leading, spacing: 6) {
                    Text("Health Notes (optional)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.phTextSecondary)
                    TextEditor(text: $vm.healthNotes)
                        .frame(minHeight: 80)
                        .padding(10)
                        .background(Color.phSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.phBorder, lineWidth: 1))
                        .overlay(alignment: .topLeading) {
                            if vm.healthNotes.isEmpty {
                                Text("e.g. Recent vet check, any allergies...")
                                    .font(.body)
                                    .foregroundStyle(Color.phTextSecondary.opacity(0.6))
                                    .padding(14)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                // Behaviour tags
                VStack(alignment: .leading, spacing: 10) {
                    Text("Personality Tags")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.phTextSecondary)

                    FlowLayout(spacing: 8) {
                        ForEach(AddPetViewModel.behaviorOptions, id: \.self) { tag in
                            let selected = vm.behaviorTags.contains(tag)
                            Button {
                                if selected { vm.behaviorTags.remove(tag) }
                                else        { vm.behaviorTags.insert(tag) }
                            } label: {
                                HStack(spacing: 4) {
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    Text(tag)
                                        .font(.system(size: 13, weight: selected ? .semibold : .regular))
                                }
                                .foregroundStyle(selected ? Color.phPrimary : Color.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selected ? Color.phPrimary.opacity(0.1) : Color.phSurface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(selected ? Color.phPrimary : Color.phBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(response: 0.2), value: selected)
                        }
                    }
                }

                // Behaviour notes
                VStack(alignment: .leading, spacing: 6) {
                    Text("Personality Notes (optional)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.phTextSecondary)
                    TextEditor(text: $vm.behaviorNotes)
                        .frame(minHeight: 80)
                        .padding(10)
                        .background(Color.phSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.phBorder, lineWidth: 1))
                        .overlay(alignment: .topLeading) {
                            if vm.behaviorNotes.isEmpty {
                                Text("e.g. Loves walks, shy at first but warms up quickly...")
                                    .font(.body)
                                    .foregroundStyle(Color.phTextSecondary.opacity(0.6))
                                    .padding(14)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}
