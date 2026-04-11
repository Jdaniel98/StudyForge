import Foundation
import Combine
import Supabase

/// Manages Supabase Realtime subscriptions for group activity.
/// Publishes live session completions from group members.
@MainActor
final class RealtimeService: ObservableObject {
    @Published private(set) var activeStudiers: [ActiveStudier] = []
    @Published private(set) var isConnected = false

    private var channel: RealtimeChannelV2?
    private var currentGroupId: UUID?

    struct ActiveStudier: Identifiable, Equatable {
        let userId: UUID
        let displayName: String
        let subjectCategory: String
        let timestamp: Date

        var id: UUID { userId }
    }

    /// Subscribe to live activity for a specific group
    func subscribeToGroup(_ groupId: UUID) async {
        // Unsubscribe from previous group
        await unsubscribe()
        currentGroupId = groupId

        let channel = supabaseClient.realtimeV2.channel("group-\(groupId.uuidString)")
        self.channel = channel

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "remote_sessions"
        )

        await channel.subscribe()
        isConnected = true

        // Listen for new session inserts from group members
        Task { [weak self] in
            for await insertion in insertions {
                guard let self else { return }
                let record = insertion.record
                if let userIdStr = record["user_id"]?.stringValue,
                   let userId = UUID(uuidString: userIdStr),
                   let category = record["subject_category"]?.stringValue {
                    let studier = ActiveStudier(
                        userId: userId,
                        displayName: category, // Placeholder — privacy-safe
                        subjectCategory: category,
                        timestamp: Date()
                    )
                    // Keep only recent activity (last 10)
                    self.activeStudiers = (self.activeStudiers + [studier]).suffix(10)
                }
            }
        }
    }

    func unsubscribe() async {
        if let channel {
            await channel.unsubscribe()
        }
        channel = nil
        currentGroupId = nil
        activeStudiers = []
        isConnected = false
    }
}
