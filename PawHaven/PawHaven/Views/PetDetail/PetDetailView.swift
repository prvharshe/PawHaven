// PetDetailView.swift
// PawHaven
//
// Full pet profile. Sticky photo header, scrollable details, sticky CTA footer.

import SwiftUI
import Supabase

struct PetDetailView: View {
    let petId: UUID

    @Environment(AuthViewModel.self) private var authVM
    @State private var vm           = PetDetailViewModel()
    @State private var photoIndex   = 0
    @State private var showReport   = false
    // Chat navigation
    @State private var chatThread:  ChatNav? = nil
    @State private var isResolvingThread = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if vm.isLoading || vm.pet == nil {
                loadingView
            } else if let pet = vm.pet {
                petContent(pet)
            }

            if let pet = vm.pet, pet.status == .available {
                stickyFooter(pet)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        if let userId = authVM.currentUserId {
                            Task { await vm.toggleSave(userId: userId) }
                        }
                    } label: {
                        Image(systemName: vm.isSaved ? "heart.fill" : "heart")
                            .foregroundStyle(vm.isSaved ? Color.phDestructive : Color.primary)
                    }

                    Menu {
                        Button("Share", systemImage: "square.and.arrow.up") {}
                        Button("Report", systemImage: "flag", role: .destructive) {
                            showReport = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task { await vm.load(petId: petId) }
        .alert("Error", isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("Retry") { Task { await vm.load(petId: petId) } }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .sheet(isPresented: $showReport) {
            if let pet = vm.pet {
                ReportView(targetType: "pet", targetId: pet.id)
                    .environment(authVM)
            }
        }
        .navigationDestination(item: $chatThread) { nav in
            ChatView(
                threadId:    nav.threadId,
                petId:       nav.petId,
                petName:     nav.petName,
                petCover:    nav.petCover,
                recipientId: nav.recipientId
            )
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func petContent(_ pet: Pet) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photoCarousel(pet)

                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pet.name)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            if let breed = pet.breed {
                                Text(breed)
                                    .font(.title3)
                                    .foregroundStyle(Color.phTextSecondary)
                            }
                        }
                        Spacer()
                        Text(pet.species.emoji)
                            .font(.system(size: 40))
                    }

                    FlowLayout(spacing: 8) {
                        PHTag(text: pet.ageDisplay, type: .neutral, icon: "calendar")
                        PHTag(text: pet.gender.displayName, type: .neutral)
                        if let size = pet.size {
                            PHTag(text: size.displayName, type: .neutral)
                        }
                        if pet.vaccinated {
                            PHTag(text: "Vaccinated", type: .health, icon: "checkmark.shield.fill")
                        }
                        if pet.neutered {
                            PHTag(text: "Neutered", type: .health, icon: "scissors")
                        }
                        if let city = pet.city {
                            PHTag(text: city, type: .neutral, icon: "location.fill")
                        }
                    }

                    Divider()

                    if let desc = pet.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About \(pet.name)").font(.headline)
                            Text(desc).font(.body).foregroundStyle(Color.phTextSecondary).lineSpacing(4)
                        }
                    }

                    if let health = pet.healthNotes, !health.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Health Notes", systemImage: "cross.case.fill").font(.headline)
                            Text(health).font(.body).foregroundStyle(Color.phTextSecondary)
                        }
                    }

                    if let behavior = pet.behaviorNotes, !behavior.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Personality", systemImage: "heart.text.square.fill").font(.headline)
                            Text(behavior).font(.body).foregroundStyle(Color.phTextSecondary)
                        }
                    }

                    Divider()

                    if let foster = pet.foster {
                        fosterCard(foster)
                    }
                }
                .padding(20)
                .padding(.bottom, pet.status == .available ? 90 : 20)
            }
        }
    }

    // MARK: - Photo Carousel

    private func photoCarousel(_ pet: Pet) -> some View {
        Group {
            if pet.photos.isEmpty {
                PHAsyncImage(url: nil).aspectRatio(1, contentMode: .fit)
            } else {
                TabView(selection: $photoIndex) {
                    ForEach(Array(pet.photos.enumerated()), id: \.offset) { i, url in
                        PHAsyncImage(url: url).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    // MARK: - Foster Card

    private func fosterCard(_ foster: UserProfile) -> some View {
        HStack(spacing: 12) {
            AvatarView(url: foster.avatarUrl, size: 48, initials: foster.initials)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(foster.displayName).font(.system(.body, weight: .semibold))
                    if foster.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption).foregroundStyle(Color.phPrimary)
                    }
                }
                Text("Foster · \(foster.city ?? "Unknown location")")
                    .font(.caption).foregroundStyle(Color.phTextSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.phSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phBorder, lineWidth: 1))
    }

    // MARK: - Sticky Footer

    private func stickyFooter(_ pet: Pet) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                // Save
                Button {
                    if let userId = authVM.currentUserId {
                        Task { await vm.toggleSave(userId: userId) }
                    }
                } label: {
                    Image(systemName: vm.isSaved ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(vm.isSaved ? Color.phDestructive : Color.primary)
                        .frame(width: 52, height: 52)
                        .background(Color.phSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Message Foster — resolves thread then navigates
                Button {
                    guard
                        let me     = authVM.currentUserId,
                        let foster = pet.foster,
                        me != foster.id          // can't message yourself
                    else { return }

                    isResolvingThread = true
                    Task {
                        defer { isResolvingThread = false }
                        let threadId = try? await ChatService().resolveThreadId(
                            senderId:   me,
                            receiverId: foster.id,
                            petId:      pet.id
                        )
                        chatThread = ChatNav(
                            threadId:    threadId ?? UUID(),
                            petId:       pet.id,
                            petName:     pet.name,
                            petCover:    pet.coverPhoto,
                            recipientId: foster.id
                        )
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isResolvingThread {
                            ProgressView().tint(.white)
                        } else {
                            Text("Message Foster")
                                .font(.system(.body, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.phAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isResolvingThread || authVM.currentUserId == nil || authVM.currentUserId == pet.fosterId)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack {
            Rectangle().fill(Color.phBorder).aspectRatio(1, contentMode: .fit).skeleton()
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle().fill(Color.phBorder).frame(height: 14).cornerRadius(4).skeleton()
                }
            }
            .padding()
        }
    }
}

// MARK: - Chat navigation model

struct ChatNav: Identifiable, Hashable {
    let id         = UUID()
    let threadId:    UUID
    let petId:       UUID
    let petName:     String
    let petCover:    String?
    let recipientId: UUID
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }.reduce(0) { $0 + $1 + spacing }
        return CGSize(width: proposal.width ?? 0, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let w = view.sizeThatFits(.unspecified).width
            if rowWidth + w > maxWidth && !rows.last!.isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(view)
            rowWidth += w + spacing
        }
        return rows
    }
}


#Preview {
    NavigationStack { PetDetailView(petId: UUID()) }
        .environment(AuthViewModel())
}
