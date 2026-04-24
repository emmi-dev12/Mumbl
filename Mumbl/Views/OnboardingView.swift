import SwiftUI
import AVFoundation
import WhisperKit

struct OnboardingView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    let onComplete: () -> Void

    @State private var step = 0
    @State private var accessibilityGranted = false
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadComplete = false

    var body: some View {
        ZStack {
            AppColors.base.ignoresSafeArea()

            VStack(spacing: 0) {
                progressDots.padding(.top, 28)
                Spacer()
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
                navRow.padding(.horizontal, 32).padding(.bottom, 28)
            }
        }
        .frame(width: 520, height: 520)
        .preferredColorScheme(.dark)
    }

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<5) { i in
                Capsule()
                    .fill(i <= step ? AppColors.accent : AppColors.textMuted.opacity(0.3))
                    .frame(width: i == step ? 20 : 7, height: 7)
                    .animation(.spring(response: 0.3), value: step)
            }
        }
    }

    private var navRow: some View {
        HStack {
            if step > 0 {
                Button("Back") { step -= 1 }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button(step == 4 ? "Start Dictating" : "Continue") {
                advanceStep()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
            .foregroundStyle(.black)
            .disabled(nextDisabled)
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 68))
                .foregroundStyle(AppColors.accent)
            Text("Welcome to Mumbl")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.textPrimary)
            Text("Free, private, and polished voice dictation for your Mac. Whisper anywhere — your text appears exactly where your cursor is.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: 380)
        }
        .padding(.horizontal, 40)
    }

    private var micStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "mic.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accent)
            Text("Microphone Access")
                .font(.title.bold())
                .foregroundStyle(AppColors.textPrimary)
            Text("Mumbl needs microphone permission to capture your voice. When you first use the dictation feature, macOS will ask for permission.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: 380)
            Label("Permission will be requested on first use", systemImage: "info.circle.fill")
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, 40)
    }

    private var accessibilityStep: some View {
        VStack(spacing: 18) {
            Image(systemName: accessibilityGranted ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(accessibilityGranted ? AppColors.success : AppColors.accent)
            Text("Accessibility Access")
                .font(.title.bold())
                .foregroundStyle(AppColors.textPrimary)
            Text("To insert text into any app, Mumbl needs Accessibility permission. This is used only to simulate a paste keystroke — Mumbl never reads your screen or keystrokes.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: 380)
            if !accessibilityGranted {
                VStack(spacing: 8) {
                    Button("Open System Settings") { openAccessibilitySettings() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accent)
                        .foregroundStyle(.black)
                    Button("I've granted access") { checkAccessibility() }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppColors.textSecondary)
                }
            } else {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.success)
            }
        }
        .padding(.horizontal, 40)
    }

    private var modelStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "cpu")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.processing)
            Text("Download Whisper Model")
                .font(.title.bold())
                .foregroundStyle(AppColors.textPrimary)
            Text("Mumbl uses OpenAI's Whisper for local, private transcription. The Base model (145 MB) is a great starting point — fast and accurate.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: 380)

            if isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: downloadProgress)
                        .frame(width: 260)
                        .tint(AppColors.accent)
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                }
            } else if downloadComplete {
                Label("Model downloaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.success)
            } else {
                VStack(spacing: 8) {
                    Button("Download Base Model (145 MB)") { downloadModel() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accent)
                        .foregroundStyle(.black)
                    Button("Skip — I'll use cloud") {
                        settingsVM.selectedEngineID = EngineID.openAI.rawValue
                        downloadComplete = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 40)
    }

    private var hotkeyStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "keyboard")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accent)
            Text("You're All Set!")
                .font(.title.bold())
                .foregroundStyle(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                HotkeyRow(icon: "hand.point.right.fill", shortcut: "Hold ⌥ Right", description: "Push-to-talk — hold while speaking, release to insert")
                HotkeyRow(icon: "arrow.2.squarepath", shortcut: "⌘⇧Space", description: "Toggle — press to start, press again to insert")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.surfaceHigh)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .frame(maxWidth: 380)

            Text("Both shortcuts work system-wide in any app. Change them anytime in Settings → Hotkeys.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Helpers

    private var nextDisabled: Bool {
        step == 3 && isDownloading
    }

    private func advanceStep() {
        if step == 4 { onComplete(); return }
        withAnimation { step += 1 }
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
            for i in stride(from: 0.0, to: 0.9, by: 0.05) {
                downloadProgress = i
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            do {
                _ = try await WhisperKit(model: WhisperModelSize.base.rawValue)
                settingsVM.selectedModelSizeRaw = WhisperModelSize.base.rawValue
                downloadProgress = 1.0
                downloadComplete = true
            } catch {
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
                .foregroundStyle(AppColors.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
