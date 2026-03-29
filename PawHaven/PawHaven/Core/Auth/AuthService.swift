// AuthService.swift
// PawHaven
//
// Thin wrapper around Supabase Auth. All Supabase-specific types are
// contained here so the rest of the app stays clean.

import Foundation
import Supabase

final class AuthService {
    private let client: SupabaseClient

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Auth State

    /// Async sequence of (event, session) pairs. Drive your AuthViewModel from this.
    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        client.auth.authStateChanges
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, name: String, role: UserRole) async throws {
        try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "display_name": .string(name),
                "role": .string(role.rawValue)
            ]
        )
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Current User ID

    var currentUserId: UUID? {
        get async { try? await client.auth.session.user.id }
    }
}
