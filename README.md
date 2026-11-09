# StudyForge

A Pomodoro-style study timer for iOS and macOS, built for long stretches of tracked, deliberate
study. One SwiftUI codebase targets both platforms.

Status: feature-complete for a first beta; TestFlight beta not started yet.

## Features

- **Timer** you can trust in the background, with a macOS menu bar timer, an iOS Live Activity
  and Dynamic Island, sounds, haptics and keyboard shortcuts
- **Subjects and weekly goals**, with a dashboard of streaks, a study heatmap, charts and history
- **Study groups** with leaderboards and real-time presence: see when a study partner starts a
  session
- **Home screen widgets** for today's progress and the weekly goal
- **Siri and Shortcuts** actions, CSV export of your sessions, and onboarding

## Architecture

```
SwiftUI views (Features/*)
   │
Services (timer, auth, notifications, export) and repositories
   │
   ├─ Core Data: the source of truth on the device; the app works fully offline
   └─ Supabase: auth, synced sessions, groups and leaderboards
        Postgres with row-level security on every table (supabase/migrations)
```

Private data, such as your session history, lives on the device and syncs to your own rows.
Shared data, such as group membership and leaderboards, lives in Supabase, where row-level
security policies decide who can read what, and leaderboard figures come from RPC functions
rather than direct table reads. The reasoning behind each choice (SwiftUI over React Native,
Core Data over SwiftData, Supabase over Firebase) is in
[StudyForge-Architecture-Roadmap.md](StudyForge-Architecture-Roadmap.md).

## Run it

Requires Xcode 16, iOS 17 or macOS 14, and a Supabase project.

1. Apply the migrations in `supabase/migrations/` to your Supabase project, in order.
2. Copy `StudyForge/App/Configuration/Supabase.plist.example` to `Supabase.plist` in the same
   folder and fill in your project URL and anon key. The real file is git-ignored.
3. Open `StudyForge.xcodeproj` (or regenerate it from `project.yml` with
   [XcodeGen](https://github.com/yonaskolb/XcodeGen)) and run the `StudyForge` scheme.

The app needs `Supabase.plist` to launch, even if you only use it offline.

## Tests

61 unit tests cover the timer service and the session, subject, stats and preferences
repositories, in an iOS and a macOS test
target. Run them from Xcode with ⌘U.

## Privacy

What the app stores and why: [privacy policy](docs/privacy-policy.html).
