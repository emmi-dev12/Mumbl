# Getting Started with Mumbl

## Download & Run (Easiest)

```bash
# 1. Visit releases
open https://github.com/emmi-dev12/mumbl/releases

# 2. Download latest Mumbl-DD.MM.YYYY.zip
# 3. Unzip (automatically extracts)
# 4. Drag Mumbl.app to Applications
# 5. Launch Mumbl from Applications
```

That's it! The app will guide you through setup.

## Build from Source

```bash
# Clone the repo
git clone https://github.com/emmi-dev12/mumbl
cd mumbl

# Install dependencies
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode
open Mumbl.xcodeproj

# Build & run (⌘R)
```

## First Launch Checklist

- [ ] Grant microphone permission
- [ ] Grant Accessibility permission (Settings → Privacy & Security → Accessibility)
- [ ] Download Whisper model (Base ~145MB recommended)
- [ ] Test with TextEdit: hold **⌥ Right**, speak "hello", release → "hello" appears

## Quick Start

### Push-to-talk (Default)
- **Hold ⌥ Right** while speaking
- **Release** to insert transcription

### Toggle Mode
- **Press ⌘⇧Space** to start recording
- **Press ⌘⇧Space** again to insert transcription

Both modes work simultaneously — use whichever fits your workflow.

## Settings Walkthrough

**General Tab**
- Activation mode (push-to-talk, toggle, or both)
- Indicator position (top center or near cursor)
- Sound feedback toggle
- Launch at login

**Models Tab**
- Local Whisper model: tiny, base, small, medium, large-v3
- Active engine selector
- Download progress

**AI Cleanup Tab**
- Optional: remove filler words and fix grammar
- Provider: OpenAI or Groq
- (Requires API key in Cloud APIs tab)

**Hotkeys Tab**
- Customize push-to-talk shortcut
- Customize toggle shortcut
- Test shortcuts here

**Cloud APIs Tab**
- OpenAI Whisper API key
- Groq Whisper API key
- Deepgram Nova API key
- (Keys are stored securely in Keychain)

**About Tab**
- Auto-update toggle (default: ON)
- Check frequency: hourly, daily, weekly, manual
- Check for updates now
- Links to GitHub

## Get Free API Keys

All cloud APIs have free tiers:

- **OpenAI**: $0.01/min (first $5 free) — [platform.openai.com](https://platform.openai.com/account/billing/overview)
- **Groq**: Free tier, ultra-fast — [console.groq.com/keys](https://console.groq.com/keys)
- **Deepgram**: $0.0043/min (free $200/month trial) — [console.deepgram.com](https://console.deepgram.com)

## Troubleshooting

**"Accessibility access required"**
- System Settings → Privacy & Security → Accessibility
- Click the lock, add Mumbl

**"Microphone not working"**
- System Settings → Privacy & Security → Microphone
- Make sure Mumbl is enabled

**Text not inserting**
- Check Accessibility permission (above)
- Try a different app (some apps don't support paste)
- Check if ⌘V paste works manually first

**Model download stuck**
- Close the app and delete `~/Library/Caches/huggingface`
- Relaunch and retry

## Tips & Tricks

- **Quiet mode**: Whisper works even at low volumes
- **Background noise**: Base model handles it well; upgrade to Small/Medium for noise-heavy environments
- **Multiple languages**: Whisper auto-detects 99+ languages
- **Custom vocabulary**: Add frequent terms in History (right-click) to help transcription
- **AI cleanup**: Use for professional writing; skip for casual notes
- **Fast updates**: Toggle mode often feels snappier than push-to-talk

## Privacy Guarantee

- **Local mode**: Zero data leaves your device
- **Cloud mode**: Only your audio, only to your chosen provider, only with your API key
- **No telemetry**: No tracking, no analytics, no accounts
- **Open source**: Code review the implementation: [Mumbl/Services](Mumbl/Services)

Enjoy! 🎤
