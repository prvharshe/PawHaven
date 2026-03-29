// MessagesListView.swift
// PawHaven

import SwiftUI

struct MessagesListView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = MessagesListViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.phBackground.ignoresSafeArea()

                Group {
                    if vm.isLoading && vm.threads.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.threads.isEmpty {
                        EmptyStateView(
                            systemImage: "bubble.left.and.bubble.right",
                            title: "No messages yet",
                            subtitle: "Find a pet you love and message the foster to start a conversation."
                        )
                    } else {
                        threadList
                    }
                }
            }
            .navigationTitle("Messages")
            .task {
                guard let userId = authVM.currentUserId else { return }
                await vm.load(userId: userId)
            }
            .refreshable {
                guard let userId = authVM.currentUserId else { return }
                await vm.load(userId: userId)
            }
        }
    }

    // MARK: - Thread List

    private var threadList: some View {
        List {
            ForEach(vm.threads) { thread in
                NavigationLink {
                    ChatView(
                        threadId:    thread.id,
                        petId:       thread.petId,
                        petName:     thread.pet?.name,
                        petCover:    thread.pet?.coverPhoto,
                        recipientId: thread.otherUserId
                    )
                } label: {
                    ThreadRow(thread: thread)
                }
                .listRowBackground(Color.phSurface)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .listStyle(.plain)
        .background(Color.phBackground)
    }
}

// MARK: - Thread Row

private struct ThreadRow: View {
    let thread: ChatThread

    var body: some View {
        HStack(spacing: 12) {
            // Pet thumbnail or user avatar
            if let pet = thread.pet, let cover = pet.coverPhoto {
                PHAsyncImage(url: cover.supabaseThumbnail(width: 100, quality: 60))
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                AvatarView(
                    url: thread.otherUser?.avatarUrl,
                    size: 52,
                    initials: thread.otherUser?.initials ?? "?"
                )
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(thread.pet?.name ?? thread.otherUser?.displayName ?? "Chat")
                        .font(.system(.subheadline, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(thread.lastMessageAt.relativeDisplay)
                        .font(.caption)
                        .foregroundStyle(Color.phTextSecondary)
                }

                Text(thread.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(Color.phTextSecondary)
                    .lineLimit(1)

                if let name = thread.otherUser?.displayName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(Color.phTextSecondary.opacity(0.7))
                }
            }

            // Unread badge
            if thread.unreadCount > 0 {
                Text("\(thread.unreadCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.phAccent)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    MessagesListView()
        .environment(AuthViewModel())
}
