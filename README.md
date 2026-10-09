# 🎵 TuneTrack

> **Production Flutter + Dart Music Player, Spotify Integration & Music Tracker**  
> Built for Android, iOS, and Web with an offline-first architecture, Material 3 dark aesthetics, and real-time listening analytics.

---

## 🌟 Key Features

### 1. 🎛️ High-Fidelity Music Player & Queue
* **Cross-Platform Playback**: Supports local audio files (MP3, M4A, WAV, AAC, FLAC, OGG), network streams, and royalty-free demo tracks via `just_audio` and `audio_session`.
* **Persistent Mini-Player**: Floats seamlessly above the bottom navigation bar with real-time scrub state and play/pause controls.
* **Full-Screen Player**: High-resolution artwork display, scrubbable progress bar, shuffle, repeat (Off / All / One), variable playback speed (0.5x – 2.0x), sleep timer, and track options.
* **Playback Queue**: Drag-and-drop reordering with `ReorderableListView` and track removal.
* **Audio Session Handling**: Automatic pause on headphone disconnection (`becomingNoisy`) and system audio interruptions.

### 2. 📊 Precise Listening Tracker & Analytics
* **Audible Playback Accounting**: Accurately records actual audible playback time, strictly excluding paused, buffering, seeking, or background-throttled time.
* **Qualification Threshold**: Automatically marks plays as valid when played for at least 30 seconds (or upon completion of shorter tracks).
* **Idempotent Storage**: Unique event UUIDs prevent duplicate playback counting.
* **Interactive Dashboard (`fl_chart`)**:
  * Total listening hours, valid plays, completed plays, and streak counts.
  * Timeframe filtering: **Day**, **Week**, **Month**, **Year**, **All-Time**.
  * 7-day listening activity bar chart.
  * Genre distribution breakdown pie chart.
  * Top 5 Tracks and Top 5 Artists rankings.
* **Yearly & Monthly Recap Stories**: Animated, Spotify Wrapped-inspired visual breakdown of your top songs, artists, streaks, and listening milestones.

### 3. 📂 Local Music Library & Playlists
* **System File Picker**: Integrated audio file picker for device storage across mobile, desktop, and web.
* **Playlist Management**: Create, rename, delete, and reorder custom playlists.
* **Liked Songs**: Dedicated automatic playlist with instant heart toggle across all screens.

### 4. 🔗 Official Spotify Integration (OAuth 2.0 PKCE)
* **Secure PKCE Authorization**: Industry-standard Proof Key for Code Exchange—no confidential client secrets embedded in Flutter code or web bundles.
* **Spotify Catalogue Search**: Search tracks, artists, and albums directly via the Spotify Web API.
* **Playback State & Connect**: Remote device inspection and playback synchronization.
* **Graceful Degradation**: When offline or unconfigured, the app operates 100% locally with zero crashes.

### 5. 🔒 Authentication, Privacy & Local-First Cloud Sync
* **Guest Mode by Default**: Full functionality without creating an account.
* **Safe Account Merging**: Migrates local guest listening history, streaks, and playlists to authenticated accounts upon sign-in.
* **User Data Isolation**: Strict user-level separation of private statistics and history.
* **Privacy Controls**: One-click JSON data export and permanent listening history clearing.
* **Cloud Firestore Sync**: Queue-backed synchronization with exponential retry backoff and restrictive Firestore security rules.

---

## 🎨 Design System & Palette

| Token | Hex | Role |
| :--- | :--- | :--- |
| **Primary Background** | `#121212` | Deep obsidian main backdrop |
| **Secondary Background** | `#1E1E1E` | Card surfaces & dialogs |
| **Primary Accent** | `#1DB954` | Vibrant TuneTrack emerald |
| **Secondary Accent** | `#6C5CE7` | Discovery & analytics violet |
| **Primary Text** | `#FFFFFF` | High-contrast readable typography |
| **Secondary Text** | `#B3B3B3` | Subdued metadata & labels |

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                      # App entry point with ProviderScope initialization
├── app/
│   ├── app.dart                   # MainNavigationShell & persistent MiniPlayer
│   └── theme/
│       ├── app_colors.dart        # Color palette, gradients, and overlays
│       ├── app_theme.dart         # Material 3 dark/light ThemeData
│       └── app_typography.dart   # Outfit & Inter typography
├── core/
│   ├── constants/                 # App and Spotify constants
│   ├── errors/                    # Typed AppException hierarchy
│   ├── providers.dart             # Riverpod dependency injection & streams
│   ├── utils/                     # DateFormatter, DurationFormatter, IdGenerator
│   └── widgets/                   # Reusable buttons, glass container, skeleton, image loader
├── data/
│   ├── local/                     # AppDatabase, SecureStorageService, SharedPreferences
│   ├── models/                    # TrackModel, PlaylistModel, ListeningSessionModel, UserModel
│   ├── repositories/              # Track, Playlist, Session, User, and Spotify repositories
│   └── sync/                      # CloudSyncService and FirestoreService
├── features/
│   ├── auth/                      # Login, Register, Forgot Password screens
│   ├── home/                      # Dashboard, greeting, daily goal card, trending rows
│   ├── search/                    # Global search, genre discovery, suggestions
│   ├── library/                   # Playlists, Liked Songs, Local audio importer
│   ├── player/                    # MiniPlayer, FullPlayerScreen, QueueScreen, SleepTimer
│   ├── tracker/                   # ListeningTrackerService
│   ├── stats/                     # StatsScreen, fl_chart visualizations, YearlyRecapScreen
│   └── profile/                   # Profile, SpotifyConnectScreen, Data Export
└── services/
    ├── audio/                     # AudioPlayerService & AudioSessionManager
    ├── authentication/            # FirebaseAuthService & AuthInterface
    └── spotify/                   # SpotifyAuthService (PKCE) & SpotifyApiService
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK `^3.47.7` / Dart `^3.13.5`
* Android Studio / Xcode / Chrome (for Web)

### Installation
1. Clone the repository and navigate to the project directory:
   ```bash
   git clone <repo_url>
   cd flutter_application_1
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the automated test suite:
   ```bash
   flutter test
   ```
4. Run the app on your preferred target:
   ```bash
   # Android
   flutter run -d android

   # iOS
   flutter run -d ios

   # Web
   flutter run -d chrome
   ```

---

## 🧪 Testing Suite

TuneTrack includes automated unit and widget test suites:
* `test/listening_tracker_test.dart`: Validates 30-second listening thresholds, short-track completion, and session idempotency.
* `test/stats_summary_test.dart`: Validates real-time analytics aggregation, streak calculation, and user data isolation.
* `test/playlist_test.dart`: Validates playlist CRUD, track additions, reordering, and removals.
* `test/widget_test.dart`: Validates 5-tab navigation shell, home dashboard, library, and stats screens.

To run all tests:
```bash
flutter test
```

---

## 🔒 Security & Firestore Rules

TuneTrack ships with restrictive Firestore rules (`firestore.rules`):
* Private user listening history and profiles are only readable/writable by the authenticated owner.
* Playlists are private by default and accessible only when explicitly marked public.
