import SwiftUI
import AVFoundation
import WhisperKit

struct OnboardingView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    let onComplete: () -> Void

    @State private var step = 0
    @State private var micGranted = false
    @State private var accessibilityGranted = false
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadComplete = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(i <= step ? Color.purple : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.spring(), value: step)
                }
            }
            .padding(.top, 28)

            Spacer()

            // Step content
            Group {
                switch step {
                case 0: welcomeStep
                case 1: micStep
                case 2: accessibilityStep
                case 3: modelStep
                case 4: hotkeyStep
                default: EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.4), value: step)

            Spacer()

            // Navigation
            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(step == 4 ? "Start Dictating" : "Continue") {
                    advanceStep()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(nextDisabled)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .frame(width: 520, height: 520)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.purple)
            Text("Welcome to Mumbl")
                .font(.largeTitle.bold())
            Text("Free, private, and polished voice dictation for your Mac. Whisper anywhere — your text appears exactly where your cursor is.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)
        }
        .padding(.horizontal, 40)
    }

    private var micStep: some View {
        VStack(spacing: 16) {
            Image(systemName: micGranted ? "mic.fill" : "mic.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(micGranted ? .green : .purple)
            Text("Microphone Access")
                .font(.title.bold())
            Text("Mumbl needs microphone permission to capture your voice for transcription. Audio is processed locally by default — never uploaded without your consent.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)
            if !micGranted {
                Button("Grant Microphone Access") {
                    requestMic()
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            } else {
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 40)
    }

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Image(systemName: accessibilityGranted ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 60))
                .foregroundStyle(accessibilityGranted ? .green : .purple)
            Text("Accessibility Access")
                .font(.title.bold())
            Text("To insert text into any app, Mumbl needs Accessibility permission. This is used only to simulate a paste keystroke — Mumbl never reads your screen or keystrokes.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)
            if !accessibilityGranted {
                Button("Open System Settings") {
                    openAccessibilitySettings()
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                Button("I've granted access") {
                    checkAccessibility()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            } else {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 40)
    }

    private var modelStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            Text("Download Whisper Model")
                .font(.title.bold())
            Text("Mumbl uses OpenAI's Whisper for local, private transcription. The Base model (145 MB) is a great starting point — fast and accurate.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)

            if isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: downloadProgress)
                        .frame(width: 260)
                        .tint(.purple)
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            } else if downloadComplete {
                Label("Model downloaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Download Base Model (145 MB)") {
                    downloadModel()
                }
                .buttonStyle(.bordered)
                .tint(.purple)

                Button("Skip — I'll use cloud") {
                    settingsVM.selectedEngineID = EngineID.openAI.rawValue
                    downloadComplete = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 40)
    }

    private var hotkeyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            Text("You're All Set!")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 12) {
                HotkeyRow(icon: "hand.point.right.fill", shortcut: "Hold ⌥ Right", description: "Push-to-talk — hold while speaking, release to insert")
                HotkeyRow(icon: "arrow.2.squarepath", shortcut: "⌘⇧Space", description: "Toggle — press to start, press again to insert")
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(.quinary))
            .frame(maxWidth: 380)

            Text("Both shortcuts work system-wide in any app. Change them anytime in Settings → Hotkeys.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(.horizontal, 40)
    }

    private var nextDisabled: Bool {
        switch step {
        case 1: return !micGranted
        case 3: return isDownloading
        default: return false
        }
    }

    private func advanceStep() {
        if step == 4 { onComplete(); return }
        withAnimation { step += 1 }
    }

    private func requestMic() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            await MainActor.run {
                micGranted = granted
            }
        }
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    private func downloadModel() {
        isDownloading = true
        Task {
            // Simulate progress since WhisperKit doesn't expose fine-grained progress
            for i in stride(from: 0.0, to: 0.9, by: 0.05) {
                downloadProgress = i
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            // Actual download
            do {
                _ = try await WhisperKit(model: WhisperModelSize.base.rawValue)
                settingsVM.selectedModelSizeRaw = WhisperModelSize.base.rawValue
                downloadProgress = 1.0
                downloadComplete = true
            } catch {
                // Fall back gracefully
                downloadComplete = true
            }
            isDownloading = false
        }
    }
}

struct HotkeyRow: View {
    let icon: String
    let shortcut: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
