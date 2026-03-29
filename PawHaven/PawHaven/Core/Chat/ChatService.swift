// ChatService.swift
// PawHaven
//
// Handles all messaging: fetch threads, fetch messages, send, mark-read,
// and real-time subscription via Supabase Realtime.
//
// SUPABASE SETUP: Run supabase_phase2.sql to enable Realtime on messages
// and create the get_user_threads() RPC.

import Foundation
import Supabase

final class ChatService {
    private let client: SupabaseClient

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    // MARK: - Threads

    /// Returns all conversation threads for a user, newest first.
    /// Requires the get_user_threads() RPC (see supabase_phase2.sql).
    func fetchThreads(userId: UUID) async throws -> [ChatThread] {
        try await client
            .rpc("get_user_threads", params: ["p_user_id": userId.uuidString])
            .execute()
            .value
    }

    // MARK: - Messages

    func fetchMessages(threadId: UUID) async throws -> [Message] {
        try await client
            .from("messages")
            .select()
            .eq("thread_id", value: threadId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    // MARK: - Send

    func sendMessage(
        threadId: UUID,
        petId: UUID?,
        senderId: UUID,
        receiverId: UUID,
        body: String
    ) async throws -> Message {
        struct Insert: Encodable {
            let threadId: UUID
            let petId: UUID?
            let senderId: UUID
            let receiverId: UUID
            let body: String
            enum CodingKeys: String, CodingKey {
                case threadId   = "thread_id"
                case petId      = "pet_id"
                case senderId   = "sender_id"
                case receiverId = "receiver_id"
                case body
            }
        }
        return try await client
            .from("messages")
            .insert(Insert(threadId: threadId, petId: petId, senderId: senderId, receiverId: receiverId, body: body))
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Mark Read

    func markRead(threadId: UUID, userId: UUID) async throws {
        try await client
            .from("messages")
            .update(["read": true])
            .eq("thread_id", value: threadId.uuidString)
            .eq("receiver_id", value: userId.uuidString)
            .eq("read", value: false)
            .execute()
    }

    // MARK: - Thread ID

    /// Deterministic thread ID: same pair of users + pet always gets the same thread.
    /// Checks the DB first; creates a new UUID only when no thread exists yet.
    func resolveThreadId(senderId: UUID, receiverId: UUID, petId: UUID) async throws -> UUID {
        struct Row: Decodable {
            let threadId: UUID
            enum CodingKeys: String, CodingKey { case threadId = "thread_id" }
        }

        let sorted = [senderId.uuidString, receiverId.uuidString].sorted()

        let existing: [Row] = try await client
            .from("messages")
            .select("thread_id")
            .or("and(sender_id.eq.\(sorted[0]),receiver_id.eq.\(sorted[1])),and(sender_id.eq.\(sorted[1]),receiver_id.eq.\(sorted[0]))")
            .eq("pet_id", value: petId.uuidString)
            .limit(1)
            .execute()
            .value

        return existing.first?.threadId ?? UUID()
    }

    // MARK: - Realtime

    /// Returns an AsyncStream of newly inserted messages for a thread.
    /// Subscribe once per ChatView; cancelled automatically when the Task is cancelled.
    func messageStream(threadId: UUID) async -> AsyncStream<Message> {
        let channel = client.channel("messages:\(threadId.uuidString)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "thread_id=eq.\(threadId.uuidString)"
        )

        await channel.subscribe()

        return AsyncStream<Message> { continuation in
            continuation.onTermination = { _ in
                Task { await channel.unsubscribe() }
            }
            Task {
                for await insert in insertions {
                    if let msg = try? insert.decodeRecord(as: Message.self) {
                        continuation.yield(msg)
                    }
                }
                continuation.finish()
            }
        }
    }
}
