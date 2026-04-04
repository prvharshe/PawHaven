// ReportService.swift
// PawHaven

import Foundation
import Supabase

final class ReportService {
    private let client: SupabaseClient

    init(client: SupabaseClient = .shared) {
        self.client = client
    }

    func submitReport(
        reporterId: UUID,
        targetType: String,
        targetId: UUID,
        reason: String
    ) async throws {
        struct ReportInsert: Encodable {
            let reporterId: UUID
            let targetType: String
            let targetId:   UUID
            let reason:     String

            enum CodingKeys: String, CodingKey {
                case reporterId = "reporter_id"
                case targetType = "target_type"
                case targetId   = "target_id"
                case reason
            }
        }

        try await client
            .from("reports")
            .insert(ReportInsert(
                reporterId: reporterId,
                targetType: targetType,
                targetId:   targetId,
                reason:     reason
            ))
            .execute()
    }
}
