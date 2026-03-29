// PawHavenApp.swift
// PawHaven

import SwiftUI

@main
struct PawHavenApp: App {
    @State private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authVM)
        }
    }
}
