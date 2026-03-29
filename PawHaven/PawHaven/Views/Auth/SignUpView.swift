// SignUpView.swift
// PawHaven

import SwiftUI

struct SignUpView: View {
    var preselectedRole: UserRole = .adopter

    @Environment(AuthViewModel.self) private var authVM

    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var role: UserRole

    init(preselectedRole: UserRole = .adopter) {
        self.preselectedRole = preselectedRole
        _role = State(initialValue: preselectedRole)
    }

    var body: some View {
        @Bindable var authVM = authVM

        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.phPrimary)

                    Text("Create your account")
                        .font(.system(.title, design: .rounded, weight: .bold))

                    Text("Join PawHaven — it's free.")
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)
                }
                .padding(.top, 24)

                // Form
                VStack(spacing: 16) {
                    PHTextField(
                        label: "Full Name",
                        placeholder: "Jane Smith",
                        text: $name
                    )

                    PHTextField(
                        label: "Email",
                        placeholder: "you@example.com",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    PHTextField(
                        label: "Password",
                        placeholder: "Min. 8 characters",
                        text: $password,
                        isSecure: true
                    )

                    // Role selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("I am a...")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.phTextSecondary)

                        Picker("Role", selection: $role) {
                            ForEach(UserRole.allCases.filter { $0 != .both }, id: \.self) { r in
                                Text(r.shortName).tag(r)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Strength indicator
                if !password.isEmpty {
                    PasswordStrengthView(password: password)
                }

                // CTA
                VStack(spacing: 8) {
                    PHButton(title: "Create Account", style: .primary, isLoading: authVM.isLoading) {
                        Task {
                            await authVM.signUp(email: email, password: password, name: name, role: role)
                        }
                    }
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1 : 0.5)

                    Text("By continuing you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption2)
                        .foregroundStyle(Color.phTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.phBackground.ignoresSafeArea())
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { authVM.errorMessage != nil },
            set: { if !$0 { authVM.clearError() } }
        )) {
            Button("OK") { authVM.clearError() }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
    }

    private var formIsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.isEmpty && email.contains("@") &&
        password.count >= 8
    }
}

// MARK: - Password Strength
private struct PasswordStrengthView: View {
    let password: String

    private var strength: Int {
        var score = 0
        if password.count >= 8  { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.contains(where: \.isNumber)     { score += 1 }
        if password.contains(where: \.isUppercase)  { score += 1 }
        return score
    }

    private var label: String {
        switch strength {
        case 0, 1: return "Weak"
        case 2, 3: return "Fair"
        default:   return "Strong"
        }
    }

    private var color: Color {
        switch strength {
        case 0, 1: return .phDestructive
        case 2, 3: return .phAccent
        default:   return .phSuccess
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < strength ? color : Color.phBorder)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.2), value: strength)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(preselectedRole: .foster)
    }
    .environment(AuthViewModel())
}
