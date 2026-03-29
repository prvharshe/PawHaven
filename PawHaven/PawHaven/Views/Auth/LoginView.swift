// LoginView.swift
// PawHaven

import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM

    @State private var email    = ""
    @State private var password = ""
    @State private var showForgotPassword = false

    var body: some View {
        @Bindable var authVM = authVM

        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.phPrimary)

                    Text("Welcome back")
                        .font(.system(.title, design: .rounded, weight: .bold))

                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)
                }
                .padding(.top, 24)

                // Form
                VStack(spacing: 16) {
                    PHTextField(
                        label: "Email",
                        placeholder: "you@example.com",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    PHTextField(
                        label: "Password",
                        placeholder: "••••••••",
                        text: $password,
                        isSecure: true
                    )

                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            showForgotPassword = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.phPrimary)
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    PHButton(title: "Sign In", style: .primary, isLoading: authVM.isLoading) {
                        Task { await authVM.signIn(email: email, password: password) }
                    }
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1 : 0.5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.phBackground.ignoresSafeArea())
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { authVM.errorMessage != nil },
            set: { if !$0 { authVM.clearError() } }
        )) {
            Button("OK") { authVM.clearError() }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    private var formIsValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
}

// MARK: - Forgot Password

private struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email      = ""
    @State private var sent       = false
    @State private var isLoading  = false
    @State private var errorMsg: String? = nil

    private let authService = AuthService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter your email and we'll send a reset link.")
                    .font(.subheadline)
                    .foregroundStyle(Color.phTextSecondary)
                    .multilineTextAlignment(.center)

                PHTextField(
                    label: "Email",
                    placeholder: "you@example.com",
                    text: $email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )

                if sent {
                    Label("Check your inbox — reset link sent!", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.phSuccess)
                        .multilineTextAlignment(.center)

                    PHButton(title: "Done", style: .secondary) { dismiss() }
                } else {
                    PHButton(title: "Send Reset Link", style: .primary, isLoading: isLoading) {
                        guard !email.isEmpty else { return }
                        isLoading = true
                        errorMsg  = nil
                        Task {
                            defer { isLoading = false }
                            do {
                                try await authService.resetPassword(email: email)
                                sent = true
                            } catch {
                                errorMsg = error.localizedDescription
                            }
                        }
                    }
                    .disabled(email.isEmpty || isLoading)
                    .opacity(email.isEmpty ? 0.5 : 1)
                }

                if let errorMsg {
                    Text(errorMsg)
                        .font(.caption)
                        .foregroundStyle(Color.phDestructive)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environment(AuthViewModel())
}
