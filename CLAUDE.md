# CLAUDE.md — StudyForge

## Project Overview

StudyForge is a native macOS/iOS Pomodoro-style study session timer for serious, sustained learning. It tracks deep work hours per subject, sets weekly targets, visualizes progress via heatmaps and streaks, and supports multi-user study groups with leaderboards and real-time presence.

**Architecture document:** See `StudyForge-Architecture-Roadmap.md` for full technical decisions, data models, and phased roadmap.

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI (shared codebase, macOS + iOS via `#if os()`)
- **Local persistence:** Core Data with `NSPersistentContainer` (optional `NSPersistentCloudKitContainer` for personal iCloud sync)
- **Remote backend:** Supabase (Postgres, Auth, Realtime, RLS)
- **Supabase SDK:** `supabase-swift` (only third-party dependency)
- **Charts:** Swift Charts (Apple framework)
- **Widgets:** WidgetKit
- **Minimum targets:** iOS 17.0, macOS 14.0

## Architecture

**Pattern:** MVVM + Repository + Sync Layer

```
Views → ViewModels → Repositories → Core Data (local) / Supabase (remote)
                                  → Sync Layer (Core Data ↔ Supabase)
                                  → Services (Timer, Auth, Notifications, Haptics, Sound)
```

**Hard rules:**
- ViewModels never import `CoreData` or `Supabase`. They only talk to Repositories and Services.
- Repositories abstract all persistence. A ViewModel calling `SessionRepository.save()` doesn't know if it writes to Core Data, Supabase, or both.
- The Sync Layer (`Core/Sync/`) is the only code that touches both Core Data and Supabase simultaneously.
- Services are `ObservableObject` singletons injected via `@EnvironmentObject` or a lightweight DI container.

## Project Structure

```
StudyForge/
├── App/                            # App entry points, AppDelegate, config
├── Core/
│   ├── Models/                     # Core Data NSManagedObject subclasses
│   ├── Repositories/               # CRUD abstraction (local + remote)
│   ├── Services/                   # TimerService, AuthService, NotificationService, etc.
│   ├── Sync/                       # SessionSyncService, RealtimeService, ConnectivityMonitor
│   └── Persistence/                # PersistenceController, .xcdatamodeld
├── Features/                       # Feature modules (Timer, Dashboard, Subjects, Groups, etc.)
│   └── <Feature>/
│       ├── <Feature>View.swift
│       └── <Feature>ViewModel.swift
├── DesignSystem/                   # Theme, Typography, Spacing, reusable SF* components
│   ├── Components/                 # SFCard, SFButton, SFProgressRing, SFAvatar, etc.
│   └── Extensions/                 # Color+Hex, Date+Helpers, View+Modifiers
├── Widgets/                        # WidgetKit extensions (iOS + macOS)
└── Tests/
    ├── Unit/
    └── Integration/
```

## Key Data Types

### Core Data Entities (Local)

- **Subject** — name, shortName, color (hex string), icon (SF Symbol), category, weeklyTargetMinutes, isArchived
- **StudySession** — subject (relationship), startedAt, endedAt, durationSeconds, plannedDurationSeconds, completedFully, notes, pomodoroCount, syncedToRemote, remoteId
- **WeeklyGoal** — subject (relationship), weekStartDate (Monday-normalized), targetMinutes, achieved
- **DailyStreak** — date (midnight-normalized), totalMinutes, subjectBreakdown (Transformable dict)
- **User** — local profile with optional supabaseId link
- **UserPreferences** — timer durations, sound/haptics toggles, iCloud sync toggle

### Supabase Tables (Remote)

- **profiles** — mirrors auth.users, holds display_name, avatar_url, lifetime stats, is_public flag
- **remote_sessions** — user_id, subject_name (denormalized string, NOT a FK), subject_category, started_at, duration_seconds, completed_fully
- **study_groups** — name, invite_code (8-char unique), created_by, max_members (default 20)
- **group_members** — group_id, user_id, role (admin|member)

All remote tables use Row Level Security. Users can only read/write their own sessions. Group aggregate stats are exposed via Postgres RPC functions, never raw row access.

## Coding Conventions

### Swift Style

- Use `struct` for Views, `class` for ViewModels (`ObservableObject`).
- Prefer `@Published` properties in ViewModels over Combine pipelines unless the pipeline is genuinely simpler.
- Use `async/await` for all asynchronous work. No Combine publishers for network calls or Core Data fetches — use `async` wrappers.
- Error handling: ViewModels expose an `@Published var error: AppError?` that Views bind to for alert presentation. Never `try!` or force-unwrap optionally-failing operations.
- Mark platform-specific code with `#if os(macOS)` / `#if os(iOS)`. Keep these blocks as small as possible — extract platform-specific logic into dedicated files when they exceed ~15 lines.

### Naming

- Design system components are prefixed `SF` (StudyForge): `SFCard`, `SFButton`, `SFProgressRing`.
- ViewModels are suffixed `ViewModel`: `TimerViewModel`, `DashboardViewModel`.
- Repositories are suffixed `Repository`: `SessionRepository`, `GroupRepository`.
- Sync services are suffixed `SyncService`: `SessionSyncService`, `ProfileSyncService`.
- Use descriptive names over abbreviations. `durationSeconds` not `durSec`. `weeklyTargetMinutes` not `wkTgtMin`.

### Core Data

- All writes happen on background contexts (`performBackgroundTask`). Never write on the main context.
- Reads for UI can use the `viewContext` (main queue).
- Fetch requests live in Repository methods, never in Views or ViewModels.
- Use `NSFetchedResultsController` (wrapped in an `ObservableObject`) for lists that need live updates (History, Subjects).

### Supabase

- The `SupabaseClient` is initialized once in `App/Configuration/Environment.swift` and injected as a dependency.
- Auth tokens are managed by `supabase-swift` automatically. Never store tokens manually.
- All Supabase calls go through Repositories, never called directly from ViewModels.
- Use Supabase RPC (Postgres functions) for aggregates — never fetch raw rows to aggregate client-side.

### Design System

- All colors come from `Theme.swift` semantic tokens. Never use raw hex or `.blue` in feature code.
- All spacing uses the spacing scale (4/8/12/16/24/32/48). No magic numbers.
- All corner radii use theme constants. Default is 12pt for cards, 8pt for buttons, 20pt for sheets.
- Dark mode is the primary design target. Light mode must also work but dark is designed first.

## TimerService — Critical Implementation Notes

The timer is the most sensitive component. Follow these rules exactly:

- Use `DispatchSourceTimer` on a background queue. Never `Timer.publish` (RunLoop-dependent, pauses during scroll, unreliable when backgrounded).
- On app background: persist `targetEndDate` to `UserDefaults`. On foreground: recompute `remainingSeconds` from `Date.now` vs `targetEndDate`.
- Schedule `UNNotificationRequest` with the exact fire date at session start. Cancel it if the user manually stops.
- On macOS: timer countdown displays in `MenuBarExtra`. On iOS: timer is the primary view.
- When a session completes: (1) write `StudySession` to Core Data, (2) update `DailyStreak`, (3) enqueue remote sync if authenticated, (4) broadcast completion to study groups via `RealtimeService`.
- Anti-gaming: sessions exceeding 3 hours without a pause are flagged (`excludedFromLeaderboard = true`).

## Sync Layer — Critical Implementation Notes

- `SessionSyncService` runs on a background queue. It queries Core Data for `syncedToRemote == false`, batches them, and pushes to Supabase.
- On success: flip `syncedToRemote = true` and set `remoteId`.
- On failure: log the error, increment a retry counter, retry with exponential backoff (1s, 2s, 4s, 8s... max 5 min).
- Sync is triggered: (a) immediately on session complete, (b) on app foreground, (c) on connectivity restore (via `NWPathMonitor`).
- `ConnectivityMonitor` wraps `NWPathMonitor` and publishes a `@Published var isConnected: Bool`.
- Sessions are append-only and immutable. There is no update or delete sync path. This eliminates conflict resolution entirely.

## Multi-User — Privacy Model

- Group members see **aggregated weekly stats only**: total hours, hours by category, streak length.
- Group members **never** see: raw session timestamps, specific subject names (only categories), session notes, session-level durations.
- Aggregation is enforced server-side via Postgres RPC functions and RLS policies. The client cannot bypass this.
- The `is_public` flag on profiles controls global leaderboard visibility. Default is `false`.

## Testing Strategy

- **Unit tests** cover: `TimerService` state transitions, `SessionRepository` CRUD, `StatsRepository` aggregation logic, `SessionSyncService` retry/backoff, anti-gaming flag logic.
- **Integration tests** cover: Supabase auth flow, session sync round-trip, RLS policy enforcement.
- Use `@MainActor` for ViewModel tests to avoid threading issues.
- Mock Supabase with a protocol-based client. Mock Core Data with an in-memory `NSPersistentContainer`.
- No snapshot tests initially — they're high-maintenance for a rapidly iterating UI. Add them in Phase 5 when the design stabilizes.

## Build & Run

```bash
# Open in Xcode
open StudyForge.xcodeproj

# Or if using SPM workspace
open Package.swift

# Supabase local dev (optional, for backend iteration)
supabase init
supabase start
supabase db reset    # applies migrations in supabase/migrations/
```

### Environment Setup

1. Copy `App/Configuration/Supabase.plist.example` to `Supabase.plist`.
2. Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` from your Supabase project dashboard.
3. For local Supabase dev, use `http://127.0.0.1:54321` and the local anon key from `supabase status`.
4. CloudKit requires an Apple Developer account and the iCloud entitlement enabled in Xcode.

### Scheme Configuration

- **StudyForge (iOS)** — runs on iPhone simulator or device.
- **StudyForge (macOS)** — runs as native macOS app with menu bar extra.
- **StudyForgeWidgetExtension** — builds and previews WidgetKit widgets.
- **StudyForgeTests** — runs unit + integration test suite.

## Phase Status

| Phase | Status | Notes |
|---|---|---|
| 1 — Core Timer | Not started | Timer, subjects, session logging, menu bar |
| 2 — Dashboard & Goals | Not started | Heatmap, charts, streaks, weekly review |
| 3 — Auth & Multi-User | Not started | Supabase, auth, groups, leaderboards, presence |
| 4 — Sync & Widgets | Not started | CloudKit, WidgetKit, Focus mode, export |
| 5 — Polish | Not started | Sounds, shortcuts, Siri, onboarding |

## Common Pitfalls

- **Don't use `Timer.publish` for the Pomodoro timer.** It will drift and pause during scrolling. Use `DispatchSourceTimer`.
- **Don't import `CoreData` in ViewModels.** Go through Repositories.
- **Don't import `Supabase` in ViewModels.** Go through Repositories.
- **Don't aggregate remote data client-side.** Use Supabase RPC functions.
- **Don't forget `syncedToRemote` flag.** Every new `StudySession` defaults to `false`. The sync layer handles the rest.
- **Don't hardcode colors.** Use `Theme` semantic tokens.
- **Don't skip the `DailyStreak` update.** When saving a session, also update or create the corresponding `DailyStreak` entity. The dashboard depends on it.
- **Don't force-unwrap Supabase responses.** Network calls fail. Handle errors gracefully and surface them via the ViewModel's `error` property.
- **Don't forget account deletion.** App Store requires it (Guideline 5.1.1). The Profile screen must have a "Delete Account" option that cascades via Supabase `ON DELETE CASCADE`.
