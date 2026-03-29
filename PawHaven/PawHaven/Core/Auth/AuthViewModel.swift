// AuthViewModel.swift
// PawHaven
//
// Single source of truth for authentication state.
// Inject via .environment(authViewModel) at the app root.

import SwiftUI
import Observation
import Supabase

@Observable
@MainActor
final class AuthViewModel {
    var isAuthenticated = false
    var currentUserId: UUID?
    var isLoading = false
    var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    // MARK: - Auth State Observation
    // Call this from .task {} in ContentView so it runs for the app lifetime.

    func observeAuthState() async {
        for await (event, session) in authService.authStateChanges {
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed:
                isAuthenticated = session != nil
                currentUserId   = session?.user.id
            case .signedOut:
                isAuthenticated = false
                currentUserId   = nil
            default:
                break
            }
        }
    }

    // MARK: - Actions

    func signIn(email: String, password: String) async {
        isLoading     = true
        errorMessage  = nil
        defer { isLoading = false }
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, name: String, role: UserRole) async {
        isLoading     = true
        errorMessage  = nil
        defer { isLoading = false }
        do {
            try await authService.signUp(email: email, password: password, name: name, role: role)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() { errorMessage = nil }
}
