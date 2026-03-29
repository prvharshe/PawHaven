// ChatView.swift
// PawHaven

import SwiftUI

struct ChatView: View {
    let threadId:    UUID
    let petId:       UUID?
    let petName:     String?
    let petCover:    String?
    let recipientId: UUID

    @Environment(AuthViewModel.self) private var authVM
    @State private var vm: ChatViewModel?
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        Group {
            if let vm {
                chatBody(vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.phBackground)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                headerTitle
            }
        }
        .task {
            guard let me = authVM.currentUserId else { return }
            let chatVM = ChatViewModel(
                threadId:   threadId,
                petId:      petId,
                senderId:   me,
                receiverId: recipientId
            )
            vm = chatVM
            await chatVM.load()
        }
    }

    // MARK: - Chat body

    @ViewBuilder
    private func chatBody(_ vm: ChatViewModel) -> some View {
        @Bindable var vm = vm
        VStack(spacing: 0) {
            // Pet context banner
            if let petName {
                petBanner(name: petName, cover: petCover)
            }

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        if vm.isLoading {
                            ProgressView().padding(.top, 40)
                        } else if vm.messages.isEmpty {
                            emptyState(vm: vm)
                        } else {
                            messagesContent(vm: vm)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onAppear { scrollProxy = proxy }
                .onChange(of: vm.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy, vm: vm)
                }
            }

            Divider()

            // Input bar
            inputBar(vm: vm)
        }
        .background(Color.phBackground)
        .alert("Error", isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Messages List

    @ViewBuilder
    private func messagesContent(vm: ChatViewModel) -> some View {
        let grouped = groupByDay(vm.messages)
        ForEach(grouped, id: \.0) { day, msgs in
            MessageDateSeparator(date: day)
            ForEach(msgs) { msg in
                MessageBubble(
                    message: msg,
                    isFromMe: msg.senderId == authVM.currentUserId
                )
                .id(msg.id)
            }
        }
        Color.clear.frame(height: 1).id("bottom")
    }

    // MARK: - Empty State

    private func emptyState(vm: ChatViewModel) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(Color.phPrimary.opacity(0.4))
            Text("Start the conversation")
                .font(.headline)
            if let name = petName {
                Text("Say hi about \(name) 👋")
                    .font(.subheadline)
                    .foregroundStyle(Color.phTextSecondary)
            }
        }
        .padding(.top, 60)
    }

    // MARK: - Pet Banner

    private func petBanner(name: String, cover: String?) -> some View {
        HStack(spacing: 10) {
            PHAsyncImage(url: cover?.supabaseThumbnail(width: 80, quality: 60))
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.phTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.phSurface)
    }

    // MARK: - Input Bar

    private func inputBar(vm: ChatViewModel) -> some View {
        @Bindable var vm = vm
        return HStack(spacing: 10) {
            TextField("Message...", text: $vm.draftText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.phSurface)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.phBorder, lineWidth: 1))

            Button {
                Task { await vm.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        vm.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.phBorder : Color.phPrimary
                    )
            }
            .disabled(vm.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSending)
            .animation(.spring(response: 0.2), value: vm.draftText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    // MARK: - Toolbar title

    private var headerTitle: some View {
        VStack(spacing: 0) {
            Text(petName ?? "Chat")
                .font(.system(.subheadline, weight: .semibold))
        }
    }

    // MARK: - Helpers

    private func scrollToBottom(proxy: ScrollViewProxy, vm: ChatViewModel) {
        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
    }

    private func groupByDay(_ messages: [Message]) -> [(Date, [Message])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: messages) { cal.startOfDay(for: $0.createdAt) }
        return grouped.sorted { $0.key < $1.key }
    }
}

#Preview {
    NavigationStack {
        ChatView(
            threadId:    UUID(),
            petId:       UUID(),
            petName:     "Bella",
            petCover:    nil,
            recipientId: UUID()
        )
    }
    .environment(AuthViewModel())
}
