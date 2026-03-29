// ChatThread.swift
// PawHaven
//
// A thread is a conversation between two users about a specific pet.
// Populated by the get_user_threads() Supabase RPC.

import Foundation

/// Raw row returned by the get_user_threads() RPC.
struct ChatThread: Identifiable, Decodable {
    let id: UUID           // = threadId
    let petId: UUID?
    let otherUserId: UUID
    let lastMessage: String
    let lastMessageAt: Date
    let unreadCount: Int

    // Enriched after fetch — not in RPC row
    var pet: Pet?
    var otherUser: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id             = "thread_id"
        case petId          = "pet_id"
        case otherUserId    = "other_user_id"
        case lastMessage    = "last_message"
        case lastMessageAt  = "last_message_at"
        case unreadCount    = "unread_count"
    }
}
