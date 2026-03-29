// ContentView.swift
// PawHaven
//
// Auth-aware router. The entire app lifecycle funnels through here.
// - Not authenticated → OnboardingView
// - Authenticated     → MainTabView
//
// Auth state is observed via AuthViewModel.observeAuthState(), which
// runs as a long-lived .task for the lifetime of this view.

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.4), value: authVM.isAuthenticated)
        .task {
            // Observe Supabase auth state for the entire app lifetime.
            // This is the single place auth changes propagate to the UI.
            await authVM.observeAuthState()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
