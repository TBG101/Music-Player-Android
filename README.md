# 🎵 Music Player

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-None-lightgrey)

A clean, offline-first music player for Android. Play your local library, search YouTube, and download tracks straight to your device.

## About

A Flutter music player built around your local library — with a YouTube search and download flow baked right in. Background playback, lock-screen controls, and a local cache keep everything fast and offline-friendly.

## Features

- **Local library** — scans device audio, caches results in a local Drift database
- **Player** — full-screen and docked mini-player views
- **Background playback** — continues with media notification controls (play/pause, next/prev)
- **YouTube search & download** — search videos, download audio, convert to MP3
- **Download queue** — progress notifications with cancel/open actions
- **Artwork & metadata** — embedded album art and ID3 tags
- **Rescan** — refresh your library from the drawer
- **Permissions flow** — guided storage/notification permission checks

## Tech Stack

| Area | Package |
|------|---------|
| State management | GetX |
| Audio | just_audio, audio_service |
| Local DB | Drift |
| YouTube | youtube_explode_dart |
| Conversion | ffmpeg_kit_flutter_new_audio |
| Metadata | metadata_god |
| Notifications | awesome_notifications |

## Getting Started

**Prerequisites**

- Flutter SDK (3.0 or newer)
- Android device or emulator

**Run it**

```bash
git clone git@github.com:TBG101/Music-Player-Android.git
cd Music-Player-Android
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── app/            # App shell, theme, DI bindings
├── core/           # Services, utils, shared widgets
└── features/
    ├── library/    # Local library: scan, cache, home UI
    ├── player/     # Audio handler + player UI
    ├── youtube/    # Search, downloads, conversion queue
    └── permissions/# Permission check flow
```

Feature-first layout: each feature owns its `controller/`, `data/`, and `presentation/` layers, wired together with GetX.
