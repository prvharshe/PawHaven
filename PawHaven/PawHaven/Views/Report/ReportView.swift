// ReportView.swift
// PawHaven
//
// Sheet shown when a user reports a pet or another user.

import SwiftUI

enum ReportReason: String, CaseIterable, Identifiable {
    case abuse        = "Animal abuse or neglect"
    case scam         = "Adoption scam"
    case inappropriate = "Inappropriate content"
    case spam         = "Spam or misleading info"
    case other        = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .abuse:         return "exclamationmark.triangle.fill"
        case .scam:          return "creditcard.trianglebadge.exclamationmark.fill"
        case .inappropriate: return "eye.slash.fill"
        case .spam:          return "envelope.badge.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }
}

struct ReportView: View {
    let targetType: String
    let targetId: UUID

    @Environment(\.dismiss)    private var dismiss
    @Environment(AuthViewModel.self) private var authVM

    @State private var selectedReason: ReportReason = .inappropriate
    @State private var additionalNote = ""
    @State private var isSubmitting   = false
    @State private var submitted      = false
    @State private var errorMessage:  String?       = nil

    private let reportService = ReportService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.phBackground.ignoresSafeArea()

                if submitted {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.phDestructive)
                    Text("What's the issue?")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("We review every report and take action within 24 hours.")
                        .font(.subheadline)
                        .foregroundStyle(Color.phTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Reason picker
                VStack(spacing: 0) {
                    ForEach(ReportReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: reason.icon)
                                    .font(.body)
                                    .foregroundStyle(Color.phPrimary)
                                    .frame(width: 24)

                                Text(reason.rawValue)
                                    .font(.body)
                                    .foregroundStyle(Color.primary)

                                Spacer()

                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.phPrimary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .background(
                            selectedReason == reason
                                ? Color.phPrimary.opacity(0.06)
                                : Color.phSurface
                        )

                        if reason != ReportReason.allCases.last {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.phBorder, lineWidth: 1))

                // Additional note
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional details (optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextEditor(text: $additionalNote)
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(10)
                        .background(Color.phSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.phBorder, lineWidth: 1)
                        )
                        .font(.body)
                }

                // Submit
                PHButton(title: isSubmitting ? "Submitting…" : "Submit Report",
                         style: .destructive) {
                    Task { await submit() }
                }
                .disabled(isSubmitting)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.phSuccess)

            Text("Report Submitted")
                .font(.system(.title2, design: .rounded, weight: .bold))

            Text("Thank you for keeping PawHaven safe.\nWe'll review this and take action if needed.")
                .font(.subheadline)
                .foregroundStyle(Color.phTextSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            PHButton(title: "Done", style: .primary) { dismiss() }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
    }

    // MARK: - Submit

    private func submit() async {
        guard let userId = authVM.currentUserId else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let reason = selectedReason.rawValue
            + (additionalNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
               ? "" : ": \(additionalNote.trimmingCharacters(in: .whitespacesAndNewlines))")

        do {
            try await reportService.submitReport(
                reporterId: userId,
                targetType: targetType,
                targetId:   targetId,
                reason:     reason
            )
            submitted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
