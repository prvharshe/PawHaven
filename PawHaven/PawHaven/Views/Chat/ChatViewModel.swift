// ChatViewModel.swift
// PawHaven

import SwiftUI
import Observation

@Observable
@MainActor
final class ChatViewModel {
    var messages:     [Message] = []
    var draftText:    String    = ""
    var isLoading:    Bool      = false
    var isSending:    Bool      = false
    var errorMessage: String?   = nil

    let threadId:   UUID
    let petId:      UUID?
    let senderId:   UUID
    let receiverId: UUID

    private let chatService: ChatService
    /// Held for `deinit` cancellation; `Task.cancel()` is thread-safe.
    private nonisolated(unsafe) var realtimeTask: Task<Void, Never>?

    init(
        threadId:   UUID,
        petId:      UUID?,
        senderId:   UUID,
        receiverId: UUID,
        chatService: ChatService = ChatService()
    ) {
        self.threadId    = threadId
        self.petId       = petId
        self.senderId    = senderId
        self.receiverId  = receiverId
        self.chatService = chatService
    }

    deinit { realtimeTask?.cancel() }

    // MARK: - Load

    func load() async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            messages = try await chatService.fetchMessages(threadId: threadId)
            try await chatService.markRead(threadId: threadId, userId: senderId)
            startRealtime()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Send

    func send() async {
        let body = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isSending else { return }
        draftText = ""
        isSending = true
        defer { isSending = false }
        do {
            let msg = try await chatService.sendMessage(
                threadId:   threadId,
                petId:      petId,
                senderId:   senderId,
                receiverId: receiverId,
                body:       body
            )
            // Realtime will also deliver this; dedup by id
            if !messages.contains(where: { $0.id == msg.id }) {
                messages.append(msg)
            }
        } catch {
            // Restore draft on failure
            draftText    = body
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Realtime

    private func startRealtime() {
        realtimeTask?.cancel()
        realtimeTask = Task { [weak self] in
            guard let self else { return }
            let stream = await chatService.messageStream(threadId: threadId)
            for await message in stream {
                guard !Task.isCancelled else { break }
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        }
    }
}
