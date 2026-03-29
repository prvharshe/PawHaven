// OnboardingView.swift
// PawHaven
//
// 3-screen onboarding: welcome → role selection → auth.
// Role selection stores the user's intended role so SignUpView can pre-fill it.

import SwiftUI

struct OnboardingView: View {
    @State private var selectedRole: UserRole?
    @State private var currentStep = 0
    @State private var showLogin  = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.phBackground.ignoresSafeArea()

                VStack {
                    // Step indicator
                    HStack(spacing: 8) {
                        ForEach(0..<2, id: \.self) { i in
                            Capsule()
                                .fill(i == currentStep ? Color.phPrimary : Color.phBorder)
                                .frame(width: i == currentStep ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                    .padding(.top, 16)

                    Spacer()

                    // Content
                    if currentStep == 0 {
                        welcomeStep
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        roleStep
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    Spacer()

                    // Footer CTAs
                    VStack(spacing: 12) {
                        if currentStep == 0 {
                            PHButton(title: "Get Started", style: .primary) {
                                withAnimation(.spring(response: 0.35)) {
                                    currentStep = 1
                                }
                            }
                        } else {
                            PHButton(title: "Continue", style: .primary) {
                                showSignUp = true
                            }
                            .disabled(selectedRole == nil)
                            .opacity(selectedRole == nil ? 0.5 : 1)
                        }

                        Button("I already have an account") {
                            showLogin = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.phPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .animation(.spring(response: 0.35), value: currentStep)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(preselectedRole: selectedRole ?? .adopter)
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
        }
    }

    // MARK: - Welcome Step
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.phPrimary)
                .padding(28)
                .background(Color.phPrimary.opacity(0.1))
                .clipShape(Circle())

            VStack(spacing: 10) {
                Text("Welcome to PawHaven")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Connect rescued animals with loving homes.\nEvery paw deserves a haven.")
                    .font(.body)
                    .foregroundStyle(Color.phTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Role Step
    private var roleStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What brings you here?")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("You can change this later in settings.")
                    .font(.subheadline)
                    .foregroundStyle(Color.phTextSecondary)
            }

            VStack(spacing: 14) {
                RoleCard(
                    role: .foster,
                    icon: "house.fill",
                    description: "List animals in your care and find them loving homes.",
                    isSelected: selectedRole == .foster
                ) { selectedRole = .foster }

                RoleCard(
                    role: .adopter,
                    icon: "heart.fill",
                    description: "Browse rescued animals and find your perfect companion.",
                    isSelected: selectedRole == .adopter
                ) { selectedRole = .adopter }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Role Selection Card
private struct RoleCard: View {
    let role: UserRole
    let icon: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.phPrimary : Color.phTextSecondary)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Color.phTextSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.phPrimary : Color.phBorder)
            }
            .padding(16)
            .background(Color.phSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.phPrimary : Color.phBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

#Preview {
    OnboardingView()
}
