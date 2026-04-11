import Foundation
import CoreData
import Combine
import Supabase

/// Syncs local StudySessions to Supabase remote_sessions.
/// Sessions are append-only and immutable — no conflict resolution needed.
@MainActor
final class SessionSyncService: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var pendingCount = 0

    private let persistenceController: PersistenceController
    private let connectivityMonitor: ConnectivityMonitor
    private var cancellables = Set<AnyCancellable>()
    private var retryCount = 0
    private let maxRetryDelay: TimeInterval = 300 // 5 minutes

    init(
        persistenceController: PersistenceController = .shared,
        connectivityMonitor: ConnectivityMonitor = .shared
    ) {
        self.persistenceController = persistenceController
        self.connectivityMonitor = connectivityMonitor

        // Sync when connectivity is restored
        connectivityMonitor.$isConnected
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                Task { await self?.syncPendingSessions() }
            }
            .store(in: &cancellables)

        // Sync when a session completes
        NotificationCenter.default.publisher(for: .sessionDidComplete)
            .sink { [weak self] _ in
                Task { await self?.syncPendingSessions() }
            }
            .store(in: &cancellables)
    }

    /// Called after a session completes, on app foreground, or on connectivity restore
    func syncPendingSessions() async {
        guard !isSyncing else { return }
        guard connectivityMonitor.isConnected else { return }

        // Must be authenticated
        guard (try? await supabaseClient.auth.session) != nil else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let unsynced = try fetchUnsyncedSessions()
            pendingCount = unsynced.count

            guard !unsynced.isEmpty else { return }

            // Batch into groups of 50
            let batches = stride(from: 0, to: unsynced.count, by: 50).map {
                Array(unsynced[$0..<min($0 + 50, unsynced.count)])
            }

            for batch in batches {
                try await syncBatch(batch)
            }

            retryCount = 0
            pendingCount = 0
        } catch {
            retryCount += 1
            let delay = min(pow(2.0, Double(retryCount)), maxRetryDelay)
            Task {
                try? await Task.sleep(for: .seconds(delay))
                await syncPendingSessions()
            }
        }
    }

    // MARK: - Private

    private func fetchUnsyncedSessions() throws -> [StudySession] {
        let request = StudySession.fetchUnsynced()
        return try persistenceController.viewContext.fetch(request)
    }

    private func syncBatch(_ sessions: [StudySession]) async throws {
        let userId = try await supabaseClient.auth.session.user.id

        let rows: [[String: AnyJSON]] = sessions.compactMap { session in
            guard let localId = session.id else { return nil }
            return [
                "user_id": .string(userId.uuidString),
                "local_id": .string(localId.uuidString),
                "subject_name": .string(session.subject?.wrappedShortName ?? "Unknown"),
                "subject_category": .string(session.subject?.wrappedCategory ?? "Custom"),
                "started_at": .string(ISO8601DateFormatter().string(from: session.wrappedStartedAt)),
                "ended_at": .string(ISO8601DateFormatter().string(from: session.wrappedEndedAt)),
                "duration_seconds": .integer(Int(session.durationSeconds)),
                "planned_duration_seconds": .integer(Int(session.plannedDurationSeconds)),
                "completed_fully": .bool(session.completedFully),
                "pomodoro_count": .integer(Int(session.pomodoroCount)),
                "excluded_from_leaderboard": .bool(session.exceedsLeaderboardThreshold),
            ]
        }

        // Upsert to handle retries (unique constraint on user_id + local_id)
        let response = try await supabaseClient.from("remote_sessions")
            .upsert(rows, onConflict: "user_id,local_id")
            .select("id,local_id")
            .execute()

        // Decode response to get remote IDs
        struct SyncResult: Decodable {
            let id: UUID
            let local_id: UUID
        }

        let results = try JSONDecoder().decode([SyncResult].self, from: response.data)

        // Mark sessions as synced on a background context
        try await persistenceController.performBackgroundTask { context in
            for result in results {
                let request = NSFetchRequest<StudySession>(entityName: "StudySession")
                request.predicate = NSPredicate(format: "id == %@", result.local_id as CVarArg)
                request.fetchLimit = 1

                if let session = try context.fetch(request).first {
                    session.syncedToRemote = true
                    session.remoteId = result.id.uuidString
                }
            }
        }
    }
}
