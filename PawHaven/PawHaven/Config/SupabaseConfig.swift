// SupabaseConfig.swift
// PawHaven
//
// SETUP: Replace the two placeholder strings below with your actual credentials.
// Find them in: Supabase Dashboard → Project Settings → API
//
// IMPORTANT: Add this file to .gitignore or move credentials to a .xcconfig
// before committing to a public repository.

import Foundation
import Supabase

private enum Credentials {
    static let projectURL = "https://vwqpagotdbzxhkmzlkxn.supabase.co"
    static let anonKey    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3cXBhZ290ZGJ6eGhrbXpsa3huIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3NzI2NjQsImV4cCI6MjA5MDM0ODY2NH0.4BojjkRKMznVb_FbXIlvAgMeY9f4ejJVAMYv-lyUw8U"
}

extension SupabaseClient {
    static let shared = SupabaseClient(
        supabaseURL: URL(string: Credentials.projectURL)!,
        supabaseKey: Credentials.anonKey
    )
}
