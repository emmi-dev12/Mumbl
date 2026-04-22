# Mumbl

A free, open-source, privacy-first voice dictation app for macOS — a polished alternative to Wispr Flow, Typeless, and Glaido.

## What it does

Hold a hotkey anywhere on your Mac, whisper or speak, release — your transcribed text appears exactly where your cursor is. Works in any app.

## Features

- **Local transcription** via [WhisperKit](https://github.com/argmaxinc/WhisperKit) (tiny → large-v3, runs entirely on-device)
- **Cloud transcription** via OpenAI Whisper, Groq Whisper, or Deepgram Nova
- **Push-to-talk** (hold ⌥ Right) and **toggle** (⌘⇧Space) modes
- **Floating pill indicator** showing recording/processing/done state
- **Optional AI cleanup** — removes filler words and fixes grammar before inserting
- **Transcription history** with search and copy
- **Auto-updater** with configurable check frequency (hourly/daily/weekly/manual)
- **Privacy-first** — local by default, zero data retention, cloud is always opt-in
- **Free and open source** (MIT)

## Installation

### From Release (Recommended)

1. Go to [Releases](https://github.com/emmi-dev12/mumbl/releases)
2. Download the latest `Mumbl-DD.MM.YYYY.zip`
3. Unzip and drag `Mumbl.app` to your `Applications` folder
4. Launch it and grant permissions

### From Source

#### Prerequisites

```bash
brew install xcodegen
```

#### Build & Run

```bash
git clone https://github.com/emmi-dev12/mumbl
cd mumbl
xcodegen generate
open Mumbl.xcodeproj
```

Then build and run in Xcode (⌘R).

### First Launch

1. Grant microphone access when prompted
2. Grant Accessibility access in System Settings → Privacy & Security → Accessibility
3. Download a Whisper model (Base is recommended for most users)
4. Start dictating with ⌥ Right (hold) or ⌘⇧Space (toggle)

## Architecture

```
Mumbl/
├── MumblApp.swift              # @main entry, AppDelegate, NSStatusItem
├── AppCoordinator.swift        # Service wiring + lifecycle
├── Services/
│   ├── TranscriptionEngine.swift   # Protocol
│   ├── WhisperKitEngine.swift      # Local (WhisperKit)
│   ├── OpenAIEngine.swift          # Cloud (OpenAI Whisper API)
│   ├── GroqEngine.swift            # Cloud (Groq)
│   ├── DeepgramEngine.swift        # Cloud (Deepgram)
│   ├── AudioRecordingService.swift # AVAudioEngine capture
│   ├── TextInsertionService.swift  # Clipboard + Cmd+V paste
│   ├── HotkeyService.swift         # Global shortcuts
│   ├── ModelManagerService.swift   # WhisperKit model cache
│   ├── AICleanupService.swift      # Optional text polish
│   └── KeychainService.swift       # Secure API key storage
├── ViewModels/
│   ├── AppViewModel.swift          # Recording state machine
│   ├── SettingsViewModel.swift     # User preferences
│   └── HistoryViewModel.swift      # SwiftData access
├── Views/
│   ├── MenuBarView.swift           # Popover UI
│   ├── FloatingIndicatorView.swift # Pill overlay
│   ├── HistoryView.swift           # Past transcriptions
│   ├── SettingsView.swift          # Tabbed preferences
│   └── OnboardingView.swift        # First-launch flow
└── Models/
    └── TranscriptionRecord.swift   # SwiftData model
```

## Text Insertion

Mumbl uses the industry-standard approach: save clipboard → set text → send ⌘V → restore clipboard (after 250ms). Requires Accessibility permission. Your clipboard contents are always restored.

## Updates

Mumbl checks for updates automatically using [Sparkle](https://sparkle-project.org/). You can:
- Enable/disable auto-updates in Settings → About
- Choose check frequency: hourly, daily, weekly, or manual only
- Check manually anytime via Settings → About → Check for Updates Now

**Versioning**: Mumbl uses date-based versioning (DD.MM.YYYY) — released and built automatically via GitHub Actions on every push to `main`.

## Privacy

- **Local mode**: audio never leaves your device
- **Cloud mode**: audio is sent only to the provider you select, using your own API key
- API keys are stored in macOS Keychain, never in plain text
- No analytics, no telemetry, no accounts required

## Development

GitHub Actions automatically:
1. Builds the app on every push to `main`
2. Creates a dated release (DD.MM.YYYY)
3. Packages the `.app` bundle as a ZIP
4. Updates the Sparkle appcast for in-app updates

See [.github/workflows/build-and-release.yml](.github/workflows/build-and-release.yml) for details.

## License

MIT
