# 🎤 Mumbl

> **Mumbl. Speak. Done.** The privacy-first voice dictation app that actually respects your data.

A free, open-source, lightning-fast voice dictation app for macOS. Why pay for Whispr Flow, Typeless, or Glaido when you can have something better? *And* it's open source.

---

## ⚡ How It Works

Hold a hotkey anywhere on your Mac → mumble or speak → text appears instantly in your cursor. No cloud unless you want it. No tracking. No nonsense.

**One keystroke away from transcription** anywhere you can type: Slack, Mail, Notes, Docs, Code editors—literally any app.

## ✨ Features

| Feature | Details |
|---------|---------|
| 🏠 **Local First** | Run Whisper locally on-device with [WhisperKit](https://github.com/argmaxinc/WhisperKit). Models from tiny to large-v3. No data leaves your Mac. |
| ☁️ **Or Cloud** | Choose OpenAI Whisper, Groq Whisper, or Deepgram Nova when you want maximum accuracy. |
| 🎯 **Mumbl Push-to-Talk** | Hold ⌥ Right to mumble. Release to transcribe. Lightning fast. |
| 🔄 **Mumbl Toggle Mode** | Press ⌘⇧Space to toggle mumbling on/off for hands-free transcription. |
| 💬 **Mumbl AI Cleanup** | Optional—removes filler words and fixes grammar before inserting text. |
| 📝 **Mumbl History** | Browse, search, and copy past mumbles anytime. |
| 🔐 **Privacy by Default** | Local transcription with zero cloud dependence. Cloud is always opt-in. Zero data retention. |
| 🎨 **Mumbl Indicator** | Beautiful pill-shaped overlay showing recording/processing/done states. |
| 🚀 **Mumbl Auto-Update** | Automatic updates via Sparkle. Configure frequency: hourly, daily, weekly, or manual. |
| 🎁 **Free & Open** | MIT licensed. No paywalls, no limits, no nonsense. |

## 🚀 Get Started in 2 Minutes

### 📦 Install (Recommended)

1. Grab the latest release from [Releases](https://github.com/emmi-dev12/mumbl/releases)
2. Download `Mumbl-DD.MM.YYYY.zip`
3. Unzip and drag `Mumbl.app` to Applications
4. Launch it and grant the prompts when asked

### 🔨 Build from Source

Want to hack on it? Clone and build:

```bash
# Prerequisites
brew install xcodegen

# Clone & open
git clone https://github.com/emmi-dev12/mumbl
cd mumbl
xcodegen generate
open Mumbl.xcodeproj
```

Then hit ⌘R in Xcode to run.

### ⚙️ First Launch Checklist

- ✅ Grant microphone access when prompted
- ✅ Enable Accessibility in System Settings → Privacy & Security → Accessibility
- ✅ Download a Whisper model (Base is perfect for most)
- ✅ Start dictating with **⌥ Right** (hold) or **⌘⇧Space** (toggle)

## 🏗️ Architecture

Clean, modular Swift. Designed to be maintainable and extensible.

```
Mumbl/
├── 🎯 MumblApp.swift              # App entry point, menu bar icon, app lifecycle
├── 🔀 AppCoordinator.swift        # Wires services together, manages state
│
├── 🎤 Services/
│   ├── TranscriptionEngine.swift      # Protocol defining transcription interface
│   ├── WhisperKitEngine.swift         # 🏠 Local transcription (WhisperKit)
│   ├── OpenAIEngine.swift             # ☁️ Cloud transcription (OpenAI API)
│   ├── GroqEngine.swift               # ☁️ Cloud transcription (Groq)
│   ├── DeepgramEngine.swift           # ☁️ Cloud transcription (Deepgram)
│   ├── AudioRecordingService.swift    # Captures audio via AVAudioEngine
│   ├── TextInsertionService.swift     # Pastes text via clipboard + Cmd+V
│   ├── HotkeyService.swift            # Listens for global hotkeys
│   ├── ModelManagerService.swift      # Manages WhisperKit model downloads
│   ├── AICleanupService.swift         # Optional: polishes transcribed text
│   └── KeychainService.swift          # Securely stores API keys
│
├── 📱 ViewModels/
│   ├── AppViewModel.swift             # Recording state, logic flow
│   ├── SettingsViewModel.swift        # User preferences
│   └── HistoryViewModel.swift         # SwiftData queries & UI logic
│
├── 🎨 Views/
│   ├── MenuBarView.swift              # Popover settings & status
│   ├── FloatingIndicatorView.swift    # Recording pill indicator
│   ├── HistoryView.swift              # Transcription history browser
│   ├── SettingsView.swift             # Tabbed preferences UI
│   └── OnboardingView.swift           # First-launch walkthrough
│
└── 💾 Models/
    └── TranscriptionRecord.swift       # SwiftData persisted transcription
```

## 📋 How Text Gets Inserted

Mumbl uses the battle-tested approach trusted by accessibility tools everywhere:

1. **Save** your current clipboard
2. **Set** the transcribed text
3. **Send** ⌘V to paste
4. **Restore** your original clipboard (after 250ms)

This works in literally every app—no special integrations needed. Your clipboard is always safe and restored.

*Requires Accessibility permission.* Granted during first launch.

---

## 🔧 Tech Stack

- **SwiftUI** — Modern, responsive UI
- **AVAudioEngine** — Low-latency audio capture
- **WhisperKit** — Fast on-device transcription
- **SwiftData** — History persistence & search
- **Sparkle** — Automatic updates
- **Keychain** — Secure API key storage

---

## 🎯 Why Mumbl?

| Feature | Mumbl | Whispr Flow | Typeless | Glaido |
|---------|-------|------------|----------|--------|
| **Cost** | 🎁 Free | $$ | $$ | $$ |
| **Open Source** | ✅ | ❌ | ❌ | ❌ |
| **Local First** | ✅ | ❌ | ❌ | ❌ |
| **Privacy** | ✅ Zero tracking | ⚠️ Cloud dependent | ⚠️ Cloud dependent | ⚠️ Cloud dependent |
| **Works Everywhere** | ✅ Any app | ✅ | ✅ | ✅ |
| **Customizable** | ✅ Hotkeys, models, engines | Limited | Limited | Limited |
| **Transcription History** | ✅ | ❌ | ❌ | ❌ |

---

## 🤔 FAQ

**Q: Will this send my audio to the cloud?**
A: Nope. By default, everything runs locally on your Mac using WhisperKit. Cloud transcription (OpenAI, Groq, Deepgram) is entirely opt-in.

**Q: What if I want better accuracy?**
A: Switch to a cloud engine in Settings, or use WhisperKit's larger models (medium or large-v3). More accuracy = more processing time.

**Q: Does this work in my favorite app?**
A: Almost certainly. Mumbl works in any app you can type in. If it doesn't work somewhere, [open an issue](https://github.com/emmi-dev12/mumbl/issues).

**Q: How much disk space does this need?**
A: The base Whisper model is ~141 MB. Large-v3 is ~3 GB. You only download what you use.

**Q: Is my Mumbl history private?**
A: Yes. Everything lives in SwiftData on your Mac. No cloud sync, no backup, no tracking.

**Q: Can I customize Mumbl's hotkey?**
A: Absolutely. Settings → Hotkey lets you pick any combination you want.

---

## 🚀 Getting Help

- **Found a bug?** [Open an issue](https://github.com/emmi-dev12/mumbl/issues)
- **Have a feature idea?** [Discussions](https://github.com/emmi-dev12/mumbl/discussions)
- **Want to contribute?** See below.

---

## 🤝 Contributing

We love contributions! Whether it's bug fixes, features, or documentation, here's how to help:

1. **Fork** the repo
2. **Create a branch** (`git checkout -b feature/my-awesome-idea`)
3. **Make your changes** and test them
4. **Push** your branch
5. **Open a PR** with a clear description

All PRs welcome. Let's build something awesome together.

---

## 📜 License

MIT License — use it freely, modify it, distribute it. See [LICENSE](LICENSE) for details.

---

**Made with ❤️ by [emmi-dev12](https://github.com/emmi-dev12)**

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
