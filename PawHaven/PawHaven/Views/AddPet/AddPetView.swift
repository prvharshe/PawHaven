// AddPetView.swift
// PawHaven
//
// Multi-step form shell. Each step is a child view driven by AddPetViewModel.

import SwiftUI

struct AddPetView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var vm = AddPetViewModel()

    private let stepTitles = ["Photos", "Basic Info", "Health & Behaviour", "Review & Publish"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.phBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar
                    progressBar

                    // Step content
                    Group {
                        switch vm.currentStep {
                        case 0: PhotoPickerStep(vm: vm)
                        case 1: BasicInfoStep(vm: vm)
                        case 2: HealthBehaviorStep(vm: vm)
                        case 3: ReviewPublishStep(vm: vm)
                        default: EmptyView()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.3), value: vm.currentStep)

                    Spacer()
                }

                // Bottom nav
                bottomBar
            }
            .navigationTitle(stepTitles[vm.currentStep])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: vm.publishedPet) { _, pet in
                if pet != nil { dismiss() }
            }
            .alert("Upload Failed", isPresented: .init(
                get: { vm.publishError != nil },
                set: { if !$0 { vm.publishError = nil } }
            )) {
                Button("OK") { vm.publishError = nil }
            } message: {
                Text(vm.publishError ?? "")
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<vm.totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= vm.currentStep ? Color.phPrimary : Color.phBorder)
                        .frame(height: 4)
                        .animation(.spring(response: 0.3), value: vm.currentStep)
                }
            }
            .padding(.horizontal, 20)

            Text("Step \(vm.currentStep + 1) of \(vm.totalSteps)")
                .font(.caption)
                .foregroundStyle(Color.phTextSecondary)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Bottom Nav Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if vm.currentStep > 0 {
                    PHButton(title: "Back", style: .secondary, isFullWidth: false) {
                        vm.back()
                    }
                    .frame(width: 100)
                }

                if vm.currentStep < vm.totalSteps - 1 {
                    PHButton(title: "Continue", style: .primary) {
                        vm.next()
                    }
                    .disabled(!vm.canAdvance)
                    .opacity(vm.canAdvance ? 1 : 0.5)
                } else {
                    PHButton(title: "Publish", style: .primary, isLoading: vm.isPublishing) {
                        if let userId = authVM.currentUserId {
                            Task { await vm.publish(fosterId: userId) }
                        }
                    }
                    .disabled(!vm.canAdvance || vm.isPublishing)
                    .opacity(vm.canAdvance ? 1 : 0.5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.regularMaterial)
        }
    }
}

#Preview {
    AddPetView()
        .environment(AuthViewModel())
}
