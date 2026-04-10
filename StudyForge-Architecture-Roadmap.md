# StudyForge — Architecture & Roadmap

## Product Vision

StudyForge is a cross-platform macOS/iOS Pomodoro-style study session timer designed for serious, sustained learning. It's built for anyone engaged in deep, structured study — graduate school prep, competitive programming training, CFA exam grinding, medical board review, language acquisition, or any discipline that demands tracked, accountable hours over months.

The app ships with opinionated defaults for common study domains (mathematics, algorithms, quantitative finance, machine learning, systems programming) but is fully customizable. Users create their own subjects, set weekly hour targets, and track progress through heatmaps, streaks, and weekly reviews.

**Multi-user support** is a first-class feature. Users can form study groups, see anonymized or public leaderboards, and share weekly progress summaries. The social layer is designed around *accountability*, not gamification — no badges, no XP bars, no dopamine traps. Just transparent visibility into who's putting in the hours.

### Core Design Principles

1. **Timer fidelity is non-negotiable.** If the timer is unreliable, nothing else matters. Background execution, notification accuracy, and session persistence are the foundation.
2. **Your data, your device.** Local-first architecture. The app works fully offline. Cloud sync and multi-user features are additive layers, never dependencies.
3. **Accountability over gamification.** Study groups and leaderboards exist to create social commitment, not engagement loops. No streaks-for-streaks-sake mechanics that punish rest days.
4. **Own your components.** The UI is built from a custom design system inspired by shadcn/ui's philosophy: composable primitives you control, no third-party UI framework lock-in.

---

## Platform Decision: Why Swift + SwiftUI (Not React Native, Not Electron)

**Choice: Native Swift app with SwiftUI, shared codebase for macOS and iOS.**

The target is macOS and iOS. The real contenders are SwiftUI (native), React Native, Flutter, and Electron (macOS-only with a separate iOS build). SwiftUI wins decisively:

- **Timer accuracy matters.** A Pomodoro app lives or dies on reliable background execution, notifications, and timer persistence. Native gives you `UNUserNotificationCenter`, `BGTaskScheduler`, and `NSBackgroundActivityScheduler` (macOS) without fighting a bridge layer. React Native's timer handling on iOS is notoriously unreliable when the app is backgrounded — you'd spend weeks on workarounds that SwiftUI handles natively.

- **Menu bar presence (macOS).** A study timer *must* live in the menu bar. SwiftUI's `MenuBarExtra` (macOS 13+) gives you this in ~20 lines. Electron can do it, but at the cost of 150MB+ RAM for a timer. That's indefensible.

- **Shared codebase reality.** SwiftUI lets you share 80-85% of code between macOS and iOS using `#if os(macOS)` conditionals. The data layer, business logic, and most views are identical. Platform-specific code is limited to menu bar integration, widget extensions, and minor layout adjustments.

- **Widgets.** iOS Lock Screen widgets and macOS desktop widgets showing today's study progress are a killer feature for a timer app. WidgetKit is SwiftUI-only.

- **Sign in with Apple.** Multi-user auth integrates natively. No third-party OAuth SDK to maintain.

**Tradeoff acknowledged:** If Android support becomes a priority, you'd need a separate codebase or a KMP (Kotlin Multiplatform) rewrite. For an Apple-ecosystem-first launch, this is an acceptable tradeoff. Android can come as a v2 initiative once the product-market fit is validated.

**What changes with multi-user:** CloudKit alone no longer suffices. CloudKit is device-to-device sync for a *single* iCloud account — it cannot share data between different users. Multi-user requires a shared backend. This is the single biggest architectural delta from a solo-user app and is addressed in detail below.

---

## Data Architecture

### The Two-Layer Problem: Local-First + Shared Backend

Multi-user support creates a split-brain data model. Some data is private (your session history, your subjects), some is shared (study group membership, leaderboard aggregates). The architecture must handle both without coupling them.

**Choice: Core Data (local) + Supabase (shared backend).**

#### Why Core Data for Local Storage

Core Data remains the local persistence layer. It runs fully offline, provides fast reads for the dashboard, and is battle-tested on Apple platforms.

- **Raw SQLite / GRDB:** Excellent performance, but you'd lose the managed object graph, change tracking, and migration tooling that Core Data gives you for free.
- **Realm:** MongoDB is sunsetting Realm Sync for mobile. Dead-end dependency.
- **SwiftData:** Apple's Core Data successor. Promising but still maturing (introduced WWDC 2023). CloudKit integration has rough edges as of 2025. **Revisit at WWDC 2026** — if SwiftData stabilizes, migrate the local layer. For now, Core Data is the safer bet.

#### Why Supabase for the Shared Backend (Not Firebase, Not Custom)

Multi-user features need: user authentication, a shared database for groups/leaderboards, and real-time subscriptions (so you see your study partner's session start in near-real-time). The contenders:

| Option | Pros | Cons |
|---|---|---|
| **Firebase** | Google-backed, mature | Proprietary query language, vendor lock-in, Firestore pricing unpredictable at scale, no Postgres |
| **Custom backend (Go/Rust + Postgres)** | Full control | 3-6 weeks of backend work before a single feature ships. Premature for an unvalidated product. |
| **Supabase** | Open-source Postgres, generous free tier, real-time subscriptions, Row Level Security, Auth with Apple/Google/email built-in, self-hostable if you outgrow the managed service | Younger than Firebase, smaller ecosystem |
| **CloudKit Sharing** | No backend to run | Complex API, limited to Apple devices, no web dashboard, poor multi-user query support |

**Supabase wins** because:

1. **It's Postgres.** Your leaderboard queries, group aggregates, and analytics are plain SQL. No proprietary query DSL to learn.
2. **Row Level Security (RLS).** User A cannot read User B's private sessions. This is enforced at the database level, not in application code. Security by default, not by discipline.
3. **Real-time.** Subscribe to a channel for your study group. When a member starts a session, everyone in the group gets a lightweight push. This is WebSocket-based and built into the Supabase client SDK.
4. **Auth.** Sign in with Apple, Google, email/password — all handled. JWT tokens, session refresh, the whole stack. No rolling your own auth.
5. **Self-hostable exit strategy.** If Supabase-the-company disappears, you `docker compose up` their open-source stack on any VPS. Firebase has no equivalent escape hatch.
6. **Cost.** Free tier covers 500MB database, 50K monthly active users, 2GB file storage. You won't hit paid tier for years as a study app.

**Tradeoff:** Adding Supabase means the app now has a network dependency for multi-user features. Mitigation: the local Core Data layer is the source of truth for all personal data. Multi-user features degrade gracefully — if offline, your timer works, your sessions log, your dashboard renders. Group features just show stale data until reconnection.

#### Why Not CloudKit for Multi-User

CloudKit's sharing model (`CKShare`) lets you share individual records or record zones with other iCloud users. In theory, this avoids a backend. In practice:

- **Discovery requires iCloud email.** You can't find users by username or display name. Every group invite requires knowing someone's iCloud email — terrible UX.
- **No aggregate queries.** "Show me the top 5 users in my group this week" requires fetching every user's records client-side and aggregating in-app. This doesn't scale past ~10 users.
- **No real-time presence.** CloudKit has no WebSocket/subscription model for multi-user awareness.
- **Apple-only forever.** If you ever build an Android client or web dashboard, CloudKit is a dead end.

CloudKit is kept as an *optional* device-sync layer for users who don't want multi-user features but do want their personal data on both their Mac and iPhone. This is a Settings toggle: "Sync personal data via iCloud."

### Data Model

#### Local (Core Data)

```
User (local profile, synced to Supabase)
├── id: UUID
├── supabaseId: String?             // Links to remote user, nil if offline-only
├── displayName: String
├── email: String?
├── avatarURL: String?
├── createdAt: Date
└── preferences: UserPreferences    // (relationship)

UserPreferences
├── focusDurationSeconds: Int32     // Default: 1500 (25 min)
├── shortBreakSeconds: Int32        // Default: 300 (5 min)
├── longBreakSeconds: Int32         // Default: 900 (15 min)
├── pomosBeforeLongBreak: Int16     // Default: 4
├── soundEnabled: Bool
├── hapticsEnabled: Bool
├── autoStartBreaks: Bool
├── autoStartFocus: Bool
└── iCloudSyncEnabled: Bool

Subject
├── id: UUID
├── name: String                    // "Linear Algebra (Strang)"
├── shortName: String               // "Strang"
├── color: String                   // Hex color for charts
├── icon: String                    // SF Symbol name
├── weeklyTargetMinutes: Int32      // e.g., 600 (10 hours)
├── sortOrder: Int16
├── isArchived: Bool
├── category: String                // "Mathematics", "CS Theory", "Finance", etc.
└── sessions: [StudySession]

StudySession
├── id: UUID
├── subject: Subject
├── startedAt: Date
├── endedAt: Date?
├── durationSeconds: Int32          // Actual focused time
├── plannedDurationSeconds: Int32   // What the Pomodoro was set to
├── completedFully: Bool            // Did they finish or bail?
├── notes: String?                  // Optional end-of-session reflection
├── pomodoroCount: Int16            // How many pomos in this block
├── syncedToRemote: Bool            // Has this been pushed to Supabase?
└── remoteId: String?               // Supabase row ID once synced

WeeklyGoal
├── id: UUID
├── subject: Subject
├── weekStartDate: Date             // Monday of the week (normalized)
├── targetMinutes: Int32
└── achieved: Bool                  // Computed, but cached for fast queries

DailyStreak
├── id: UUID
├── date: Date                      // Normalized to midnight
├── totalMinutes: Int32             // Aggregated, denormalized for perf
└── subjectBreakdown: [String: Int] // Transformable: {"Strang": 120, "CLRS": 90}
```

**Why denormalize `DailyStreak`?** The progress dashboard needs to render 90-180 days of data in a heatmap. Running an aggregate query across thousands of `StudySession` rows every time you open the app is wasteful. `DailyStreak` is a materialized view — updated at session-end, queried at app-launch. The tradeoff is write-time complexity (you update two entities per session), but reads become O(1) per day. For a dashboard-heavy app, this is the correct optimization.

**Why `syncedToRemote` flag on StudySession?** This is the offline-first sync marker. When a session completes offline, `syncedToRemote = false`. A background sync job picks up unsynced sessions and pushes them to Supabase. On success, it flips the flag. This is a simple, debuggable sync pattern — no conflict resolution needed because sessions are append-only and immutable after creation.

#### Remote (Supabase / Postgres)

```sql
-- Auth handled by Supabase Auth (users table is automatic)

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    total_lifetime_minutes INT DEFAULT 0,      -- Denormalized for leaderboards
    current_streak_days INT DEFAULT 0,
    longest_streak_days INT DEFAULT 0,
    is_public BOOLEAN DEFAULT false,            -- Opt-in to global leaderboard
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE remote_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    subject_name TEXT NOT NULL,                 -- Denormalized (no foreign key to local subjects)
    subject_category TEXT,
    started_at TIMESTAMPTZ NOT NULL,
    duration_seconds INT NOT NULL,
    completed_fully BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for leaderboard queries
CREATE INDEX idx_remote_sessions_user_week
    ON remote_sessions (user_id, started_at DESC);

CREATE TABLE study_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    invite_code TEXT UNIQUE NOT NULL,           -- 8-char alphanumeric, shareable
    created_by UUID NOT NULL REFERENCES profiles(id),
    max_members INT DEFAULT 20,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE group_members (
    group_id UUID REFERENCES study_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',                 -- 'admin' | 'member'
    joined_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (group_id, user_id)
);

-- Row Level Security
ALTER TABLE remote_sessions ENABLE ROW LEVEL SECURITY;

-- Users can only read their own sessions
CREATE POLICY "Users read own sessions"
    ON remote_sessions FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert their own sessions
CREATE POLICY "Users insert own sessions"
    ON remote_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Group members can read aggregate stats of other members
-- (via a Postgres function, not raw row access)
-- You see "Alex studied 12 hours this week", not Alex's raw session log
```

**Critical design decision: `subject_name` is denormalized as a plain string in `remote_sessions`, not a foreign key.** Subjects are personal. User A has "Strang" and "CLRS". User B has "Organic Chemistry" and "MCAT Verbal". There is no shared subject table. The remote database only needs the subject name for display in leaderboards and group feeds. If a user renames a subject locally, old sessions retain the old name remotely — this is acceptable and actually desirable for historical accuracy.

**Critical design decision: Group members see aggregates, not raw sessions.** This is a privacy choice. Your study group sees "Daniel studied 14 hours this week across 3 subjects." They do not see "Daniel did 47 minutes of Hull at 11:43 PM on Thursday." Aggregation happens server-side via Postgres functions exposed through Supabase RPC. This is enforced by RLS — there is no client-side workaround.

---

## App Architecture: MVVM + Repository + Sync Layer

### Why Not TCA (The Composable Architecture)?

TCA (Point-Free's framework) is the trendy choice in the Swift community. It's excellent for large teams needing strict unidirectional data flow. But for a focused productivity app:

- **Learning curve cost.** TCA's reducer/effect/store pattern adds ~2 weeks of ramp-up time before you're productive. That's 2 weeks not building features.
- **Boilerplate.** A simple timer screen in TCA requires a Reducer, Action enum, State struct, Effect publisher, Store, and ViewStore. In vanilla MVVM, it's a ViewModel and a View. The ceremony isn't justified until the team exceeds 3-4 engineers.
- **Debugging.** TCA's action-replay debugging is powerful but overkill here. Your state is a timer, a subject list, and some aggregates.

**Choice: MVVM with a Repository layer and a dedicated Sync layer.**

```
┌──────────────────────────────────────────────────┐
│                     Views                         │
│  (SwiftUI — platform-adaptive via #if os())      │
├──────────────────────────────────────────────────┤
│                  ViewModels                       │
│  TimerVM · DashboardVM · SubjectsVM              │
│  GoalsVM · HistoryVM · SettingsVM                │
│  GroupsVM · LeaderboardVM · ProfileVM            │
├──────────────────────────────────────────────────┤
│                 Repositories                      │
│  SessionRepo · SubjectRepo · GoalRepo            │
│  StatsRepo · GroupRepo · ProfileRepo             │
├──────────────────────────────────────────────────┤
│               Core Data Stack                     │
│  NSPersistentContainer (local)                   │
│  + Optional NSPersistentCloudKitContainer        │
│  + Background contexts for writes                │
├──────────────────────────────────────────────────┤
│                 Sync Layer                        │
│  SessionSyncService (Core Data → Supabase)       │
│  ProfileSyncService                              │
│  RealtimeService (Supabase Realtime channels)    │
├──────────────────────────────────────────────────┤
│                  Services                         │
│  TimerService · NotificationService              │
│  HapticsService · SoundService                   │
│  AuthService (Supabase Auth)                     │
├──────────────────────────────────────────────────┤
│               Network Layer                       │
│  SupabaseClient (supabase-swift SDK)             │
│  Connectivity monitor (NWPathMonitor)            │
└──────────────────────────────────────────────────┘
```

**Why the Repository layer?** ViewModels should not import Core Data or Supabase. The Repository abstracts both. `SessionRepository.save(session:)` writes to Core Data *and* enqueues a remote sync. The ViewModel doesn't know or care about the plumbing. If you later migrate Core Data to SwiftData, you replace Repository internals — zero ViewModel changes.

**Why a dedicated Sync Layer?** Sync is the hardest part of any local-first multi-user app. Isolating it into its own layer means:
- Sync logic is independently testable (mock Core Data, mock Supabase, assert correctness).
- Sync failures don't crash the UI. The sync layer retries with exponential backoff and logs failures silently.
- Sync cadence is configurable: immediate (on session complete), batched (every 5 minutes), or manual (user-triggered).

### TimerService — The Heart of the App

The timer is the most architecturally sensitive component. Getting it wrong means missed notifications, inaccurate session logs, and broken trust.

**Design:**

```
TimerService (ObservableObject)
├── state: TimerState (idle | running | paused | break | completed)
├── remainingSeconds: Int
├── currentSession: StudySession?
├── currentSubject: Subject?
├── pomodorosCompleted: Int
├── totalFocusSecondsToday: Int
│
├── start(subject:, duration:)
├── pause()
├── resume()
├── skip()
├── cancel()
│
├── Internal: DispatchSourceTimer (not Timer.publish)
├── Internal: Background task registration
├── Internal: Notification scheduling
└── Internal: RealtimeService.broadcast(sessionStarted:) on start
```

**Why `DispatchSourceTimer` over `Timer.publish`?** `Timer.publish` is tied to the RunLoop, which means it pauses during scrolling and is unreliable when the app is backgrounded. `DispatchSourceTimer` runs on a background queue and isn't affected by UI events. For a timer app, this is non-negotiable.

**Background strategy:**
- When app backgrounds → save `targetEndDate` to UserDefaults
- When app foregrounds → compute elapsed time from `Date()` vs `targetEndDate`
- Schedule `UNNotificationRequest` at session start with the exact fire date
- On macOS: use `NSBackgroundActivityScheduler` for periodic check-ins

This means the timer doesn't actually "run" in the background — it reconstructs state on foreground. This is the standard iOS pattern and is battery-efficient.

**Multi-user integration:** When a timer starts, `TimerService` tells `RealtimeService` to broadcast a lightweight event (`{user: "Daniel", subject: "CLRS", action: "started"}`) to the user's active study groups via Supabase Realtime. Group members see a subtle "Daniel is studying CLRS" indicator. When the session completes, another broadcast fires with the duration. This is fire-and-forget — if the broadcast fails (offline), nothing breaks.

---

## Multi-User Feature Design

### Authentication

**Choice: Supabase Auth with Sign in with Apple as primary, email/password as fallback.**

Sign in with Apple is mandatory for iOS apps that offer third-party login (App Store Review Guideline 4.8). Making it the *primary* method means:
- Most users authenticate with a single tap and FaceID/TouchID.
- No email verification flow to build.
- Apple relays a private email if the user wants to hide theirs.

Email/password exists for users who prefer it or who plan to use a future Android/web client where Apple sign-in is less natural.

**Guest mode:** The app is fully functional without authentication. Creating an account is only required to access study groups and leaderboards. This lowers the onboarding barrier — a user can run Pomodoro sessions for weeks before ever seeing a sign-up prompt. The prompt surfaces naturally when they tap "Study Groups" or "Leaderboard" for the first time.

### Study Groups

Study groups are the core social feature. A group is a private cohort of up to 20 users who can see each other's weekly aggregates.

**How it works:**
1. User A creates a group ("FAU Spring 2027 Cohort") and gets an 8-character invite code.
2. User A shares the code via iMessage, WhatsApp, email — any channel.
3. User B enters the code in-app and joins.
4. All members see a group dashboard: this week's hours per member, a group leaderboard, and a live activity feed ("Alex just completed a 50-min session on Strang").

**What you can see in a group:**
- Each member's total hours this week (by subject category, not individual subjects).
- A ranked leaderboard for the current week.
- Live session activity (who's studying right now).
- Each member's current streak.

**What you cannot see:**
- Another member's raw session log (times, durations, notes).
- Another member's specific subjects (unless they match a shared category).
- Any data from weeks the member hasn't opted to share.

**Why limit to 20 members?** Beyond ~20, the social accountability effect weakens. You stop recognizing names, the leaderboard becomes impersonal, and the feed becomes noise. 20 is a cohort, not a crowd. This can be revisited if there's demand for larger groups (e.g., university course sections), but the default is intentionally intimate.

### Leaderboards

Two types:

1. **Group leaderboard.** Ranked by weekly hours. Visible only to group members. Resets every Monday.
2. **Global leaderboard.** Opt-in only (`is_public = true` in profile). Ranked by weekly hours. Shows display name and total hours — nothing else. Exists for users who want external motivation but have no study group.

**Anti-gaming consideration:** Sessions longer than 3 hours with no pause are flagged and excluded from leaderboards (but still count for personal stats). This prevents someone from starting a timer and walking away for 8 hours to top the board. The 3-hour threshold is configurable server-side.

### Real-Time Presence

When a user starts a study session:
1. Client sends a lightweight payload to a Supabase Realtime channel named after each group the user belongs to.
2. Other members subscribed to that channel receive the event and display a subtle indicator (e.g., a green dot next to the user's name on the group screen, or a brief toast: "Daniel started studying CLRS").
3. When the session ends, another event fires.

This is Supabase's Broadcast feature (not database changes) — no database write on session-start, just an ephemeral WebSocket message. Low latency, low cost.

---

## Feature Set (Prioritized)

### Phase 1 — Core Timer + Local Data (Weeks 1-3)

| Feature | Details |
|---|---|
| Pomodoro timer | 25/50 min focus, 5/10 min short break, 15/30 min long break. All configurable per user. |
| Subject management | Create, edit, archive, color-code, categorize. Pre-seeded with common study domains on first launch. |
| Session logging | Auto-saves completed sessions to Core Data. Tracks planned vs. actual duration, completion status. |
| Basic stats | Today's total, per-subject breakdown, sessions count. |
| macOS menu bar | Timer countdown visible in menu bar. Click to expand full timer UI. |
| iOS notifications | Sound + banner at session end, 5-min warning. Configurable. |
| iOS haptics | Subtle haptic at warning and completion. |
| User preferences | Timer durations, sounds, haptics, auto-start toggles. Persisted locally. |

### Phase 2 — Dashboard & Goals (Weeks 4-6)

| Feature | Details |
|---|---|
| GitHub-style heatmap | 180-day grid showing daily study intensity. Color-coded by total hours. |
| Weekly targets | Set hours/week per subject. Progress bars with target lines. |
| Subject breakdown chart | Stacked bar chart — how hours distribute across subjects. Swift Charts. |
| Streak tracking | Current streak, longest streak. Configurable: streak breaks on zero-study days or below-minimum-hours days. |
| Weekly review | Auto-generated summary every Monday: previous week's targets hit/missed, total hours, top subject, comparison to prior week. |
| History view | Grouped by day. Each entry shows subject, duration, completion. Expandable for notes. Filterable by subject and date range. |

### Phase 3 — Auth & Multi-User (Weeks 7-10)

| Feature | Details |
|---|---|
| Authentication | Sign in with Apple (primary), email/password (fallback). Guest mode remains fully functional. |
| Profile setup | Display name, optional avatar (from device photo library). Privacy toggle: public or private. |
| Background sync | `SessionSyncService` pushes unsynced local sessions to Supabase. Exponential backoff on failure. |
| Study groups | Create group (generates invite code), join via code, leave group. Group dashboard with weekly aggregates. |
| Group leaderboard | Ranked by weekly hours. Resets Monday. Per-group. |
| Live presence | "Alex is studying CLRS" real-time indicators via Supabase Broadcast. |
| Global leaderboard | Opt-in. Weekly hours ranking across all public users. |
| Anti-gaming | Sessions >3 hours without pause excluded from leaderboards. |

### Phase 4 — Sync, Widgets & Platform Features (Weeks 11-13)

| Feature | Details |
|---|---|
| iCloud personal sync | Optional CloudKit sync for users who want cross-device personal data without creating an account. Independent of Supabase. |
| iOS Lock Screen widget | Current streak + today's hours. WidgetKit. |
| macOS desktop widget | Weekly progress per subject. |
| Focus mode integration | Auto-triggers iOS Focus Mode when timer starts (`INInteraction`). |
| Session notes | Optional markdown-light notes at session end. |
| CSV export | Export all personal session data. |

### Phase 5 — Polish & Delight (Weeks 14-16)

| Feature | Details |
|---|---|
| Ambient sounds | Lo-fi/white noise/rain during focus. Bundled audio. Configurable or disable. |
| Keyboard shortcuts (macOS) | `⌘+S` start, `⌘+P` pause, `⌘+K` skip. Fully customizable. |
| Siri Shortcuts | "Hey Siri, start a Strang session." |
| App Intents + Spotlight | Type "study" in Spotlight to start a session. |
| Onboarding | First-launch flow: create subjects, set weekly targets, optional account creation. |
| Dark/light adaptive | Follows system with manual override. |
| Push notifications (social) | "Your study group logged 40 hours this week!" — opt-in weekly digest via Supabase Edge Functions + APNs. |

---

## UI Architecture (shadcn/ui Philosophy in SwiftUI)

shadcn/ui doesn't apply directly to a native Swift app — but its design philosophy is the blueprint. shadcn's core proposition is: unstyled, composable primitives that you own and customize, with no dependency on a component library's release cycle.

### Design System

**Create a `DesignSystem/` module containing:**

- `Theme.swift` — Color tokens (semantic names: `.surfacePrimary`, `.surfaceSecondary`, `.accentFocus`, `.accentBreak`, `.textPrimary`, `.textMuted`, `.borderSubtle`), typography scale (caption, body, title, largeTitle — all using SF Pro with weight variants), spacing scale (4/8/12/16/24/32/48), corner radii. All driven by `@Environment(\.colorScheme)`.
- Reusable components: `SFCard`, `SFProgressBar`, `SFProgressRing`, `SFTag`, `SFButton` (variants: primary, secondary, ghost, destructive), `SFSheet`, `SFHeatmapCell`, `SFAvatar`, `SFBadge`, `SFLeaderboardRow`.
- Every component is a plain SwiftUI view you own. No third-party UI library. This is the shadcn philosophy in native code.

**Color palette direction:** Dark-mode-first. Deep slate backgrounds (`#0F172A`), muted borders, vibrant accent colors per subject category (Mathematics = blue, CS Theory = amber, Finance = emerald, ML = violet, etc.). Think Linear or Raycast aesthetic, not Apple's default system chrome.

**Per-subject colors:** Users assign colors when creating subjects. The app ships with a curated palette of 12 colors optimized for both light and dark mode, with sufficient contrast between adjacent items on charts.

### Key Screens

1. **Timer Screen** — Center-dominant circular progress ring. Subject name and category above, time remaining in monospace below. Minimal controls: play/pause, skip, cancel. Below the timer: today's mini-summary (hours, sessions, current streak). No clutter. The timer is sacred space.

2. **Dashboard** — Scrollable. Top: today's summary card (hours, sessions, streak, comparison to same day last week). Middle: heatmap (180 days). Bottom: per-subject weekly progress bars with target lines. Uses Swift Charts for all data visualization.

3. **Subjects** — List with color swatches, category tags, weekly targets, total hours logged all-time. Swipe to archive. Tap to edit. "Add Subject" sheet at bottom.

4. **History** — Grouped by day. Each entry shows subject, duration, completion status, and notes preview. Expandable. Filterable by subject and date range. Searchable.

5. **Study Groups** — List of groups the user belongs to. Each group expands to: weekly leaderboard, member list with this-week hours, live activity feed. "Create Group" and "Join Group" CTAs.

6. **Leaderboard** — Tab bar: "My Groups" | "Global". Ranked list with avatar, display name, weekly hours, and streak. Current user highlighted.

7. **Profile** — Display name, avatar, lifetime stats (total hours, total sessions, longest streak, top subject by hours), privacy toggle, account management.

8. **Settings** — Timer durations, notification preferences, sounds, haptics, data export, iCloud sync toggle, Supabase account management, appearance (dark/light/system).

---

## Technical Decisions Summary

| Decision | Choice | Alternative Considered | Why |
|---|---|---|---|
| Platform | Native SwiftUI | React Native, Flutter | Timer reliability, menu bar, widgets, native auth |
| Local persistence | Core Data | SwiftData, Realm, SQLite | Mature, migration path to SwiftData later |
| Remote backend | Supabase (Postgres) | Firebase, custom Go/Rust API | Open-source, SQL, RLS, real-time, self-hostable, free tier |
| Auth | Supabase Auth + Sign in with Apple | Firebase Auth, Auth0 | Native integration, App Store compliance, Supabase bundled |
| Architecture | MVVM + Repository + Sync Layer | TCA, VIPER | Right-sized complexity, testable, clear sync boundary |
| Timer engine | DispatchSourceTimer | Timer.publish, CADisplayLink | Background reliability, RunLoop independence |
| Personal sync | CloudKit (optional) | Supabase-only | Zero cost for users who don't want an account |
| Real-time | Supabase Realtime (Broadcast) | WebSocket server, Firebase RTDB | Bundled with Supabase, no separate infra |
| Charts | Swift Charts (Apple) | Custom drawing, third-party | Native, performant, accessible, maintained by Apple |
| Design system | Custom (shadcn philosophy) | Third-party component lib | Full control, no dependency risk, matches native platform idioms |

---

## Project Structure

```
StudyForge/
├── App/
│   ├── StudyForgeApp.swift
│   ├── ContentView.swift
│   ├── AppDelegate.swift              // macOS menu bar setup
│   └── Configuration/
│       ├── Supabase.plist             // URL + anon key (not secret)
│       └── Environment.swift          // Debug vs. Release config
├── Core/
│   ├── Models/
│   │   ├── Subject+CoreData.swift
│   │   ├── StudySession+CoreData.swift
│   │   ├── WeeklyGoal+CoreData.swift
│   │   └── DailyStreak+CoreData.swift
│   ├── Repositories/
│   │   ├── SessionRepository.swift
│   │   ├── SubjectRepository.swift
│   │   ├── GoalRepository.swift
│   │   ├── StatsRepository.swift
│   │   ├── GroupRepository.swift      // Supabase-backed
│   │   └── ProfileRepository.swift    // Supabase-backed
│   ├── Services/
│   │   ├── TimerService.swift
│   │   ├── NotificationService.swift
│   │   ├── HapticsService.swift
│   │   ├── SoundService.swift
│   │   └── AuthService.swift          // Wraps Supabase Auth
│   ├── Sync/
│   │   ├── SessionSyncService.swift   // Core Data → Supabase
│   │   ├── ProfileSyncService.swift
│   │   ├── RealtimeService.swift      // Supabase Broadcast
│   │   └── ConnectivityMonitor.swift  // NWPathMonitor wrapper
│   └── Persistence/
│       ├── PersistenceController.swift
│       └── StudyForge.xcdatamodeld
├── Features/
│   ├── Timer/
│   │   ├── TimerView.swift
│   │   └── TimerViewModel.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── DashboardViewModel.swift
│   │   ├── HeatmapView.swift
│   │   └── WeeklyProgressView.swift
│   ├── Subjects/
│   │   ├── SubjectsListView.swift
│   │   ├── SubjectEditorView.swift
│   │   └── SubjectsViewModel.swift
│   ├── History/
│   │   ├── HistoryView.swift
│   │   └── HistoryViewModel.swift
│   ├── Groups/
│   │   ├── GroupsListView.swift
│   │   ├── GroupDetailView.swift
│   │   ├── CreateGroupView.swift
│   │   ├── JoinGroupView.swift
│   │   └── GroupsViewModel.swift
│   ├── Leaderboard/
│   │   ├── LeaderboardView.swift
│   │   └── LeaderboardViewModel.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   ├── SignInView.swift
│   │   └── ProfileViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
├── DesignSystem/
│   ├── Theme.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   ├── Components/
│   │   ├── SFCard.swift
│   │   ├── SFProgressRing.swift
│   │   ├── SFProgressBar.swift
│   │   ├── SFButton.swift
│   │   ├── SFTag.swift
│   │   ├── SFAvatar.swift
│   │   ├── SFHeatmapCell.swift
│   │   ├── SFLeaderboardRow.swift
│   │   └── SFEmptyState.swift
│   └── Extensions/
│       ├── Color+Hex.swift
│       ├── Date+Helpers.swift
│       └── View+Modifiers.swift
├── Widgets/
│   ├── iOS/
│   │   └── StudyForgeWidget.swift
│   └── macOS/
│       └── StudyForgeDesktopWidget.swift
└── Tests/
    ├── Unit/
    │   ├── TimerServiceTests.swift
    │   ├── SessionRepositoryTests.swift
    │   ├── StatsRepositoryTests.swift
    │   ├── SessionSyncServiceTests.swift
    │   └── AntiGamingTests.swift
    └── Integration/
        └── SupabaseSyncTests.swift
```

---

## Risks & Mitigations

**Risk 1: Sync conflicts.** Two devices or the offline queue + live edit create conflicting data. **Mitigation:** StudySessions are append-only and immutable after creation — conflicts are structurally impossible for the core data type. Profile edits use last-write-wins (low stakes). WeeklyGoals use last-write-wins with a `updatedAt` timestamp to detect staleness.

**Risk 2: Supabase dependency for multi-user.** If Supabase goes down, group features break. **Mitigation:** All personal features (timer, dashboard, history, goals) work fully offline via Core Data. Multi-user is additive. Supabase is also self-hostable — if the managed service becomes unreliable or expensive, you can run it on a $5/mo VPS.

**Risk 3: Scope creep.** Building a multi-user study app is materially more complex than a solo timer. **Mitigation:** Phases 1-2 ship a fully usable single-user product. Multi-user doesn't start until Phase 3. If multi-user takes longer than expected, you still have a great personal study timer.

**Risk 4: App Store review friction.** Apps with account creation must also offer account deletion (App Store Guideline 5.1.1). **Mitigation:** Build "Delete Account" into Profile settings from day one. It triggers Supabase's `auth.admin.deleteUser()` and cascades to all remote data via `ON DELETE CASCADE`.

**Risk 5: Leaderboard gaming.** Users start timers and walk away. **Mitigation:** Sessions >3 hours without pause excluded from leaderboard rankings (configurable). Sessions still count for personal stats — we don't police personal use, only competitive fairness.

**Risk 6: macOS/iOS divergence.** Platform-specific code grows over time. **Mitigation:** The `Features/` layer is 90% shared. Only `App/`, `Widgets/`, and platform-specific services have `#if os()` conditionals. Code review discipline (even solo — diff your own PRs).

---

## Timeline

| Phase | Weeks | Milestone |
|---|---|---|
| 1 — Core Timer | 1-3 | Functional Pomodoro timer with subject tracking, session logging, macOS menu bar |
| 2 — Dashboard & Goals | 4-6 | Heatmap, weekly goals, charts, streak tracking, history view, weekly review |
| 3 — Auth & Multi-User | 7-10 | Supabase integration, auth, sync, study groups, leaderboards, real-time presence |
| 4 — Sync & Widgets | 11-13 | CloudKit personal sync, iOS/macOS widgets, Focus mode, session notes, CSV export |
| 5 — Polish & Delight | 14-16 | Ambient sounds, keyboard shortcuts, Siri, Spotlight, onboarding, push notifications |

**Total: ~16 weeks at 5-8 hrs/week side-project pace.** Phases 1-2 deliver a complete personal study timer. Phase 3 is the multi-user unlock. Phases 4-5 are platform polish.

---

## Dependencies

| Dependency | Purpose | License |
|---|---|---|
| [supabase-swift](https://github.com/supabase/supabase-swift) | Auth, Postgres client, Realtime, Storage | MIT |
| Swift Charts (Apple) | Data visualization | System framework |
| WidgetKit (Apple) | iOS/macOS widgets | System framework |
| Core Data (Apple) | Local persistence | System framework |
| CloudKit (Apple) | Optional personal device sync | System framework |

**Total third-party dependencies: 1** (`supabase-swift`). Everything else is Apple system frameworks. This is intentional — minimal dependency surface means minimal maintenance burden and no supply chain risk.
