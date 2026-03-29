// Message.swift
// PawHaven

import Foundation

struct Message: Codable, Identifiable {
    let id: UUID
    let threadId: UUID
    let petId: UUID?
    let senderId: UUID
    let receiverId: UUID
    let body: String
    var read: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case threadId   = "thread_id"
        case petId      = "pet_id"
        case senderId   = "sender_id"
        case receiverId = "receiver_id"
        case body, read
        case createdAt  = "created_at"
    }
}
