import SwiftUI
import KeyboardShortcuts

struct MenuBarView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @Environment(\.openSettings) var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(AppColors.border)
            statusCard.padding(12)
            shortcutsRow.padding(.horizontal, 12).padding(.bottom, 10)
            Divider().background(AppColors.border)
            recentSection
            Divider().background(AppColors.border)
            footerRow
        }
        .frame(width: 320)
        .background(AppColors.base)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                Text("Mumbl")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            Spacer()
            Button(action: { NSApp.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
            }
            .buttonStyle(.plain)
            .help("Quit Mumbl")
        }
        .padding(.horizontal, 14)
        .padding(.top, 13)
        .padding(.bottom, 11)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HStack(spacing: 10) {
            statusDot
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                if !statusSubtitle.isEmpty {
                    Text(statusSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            engineBadge
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(AppColors.surfaceHigh)
                .stroke(statusBorderColor.opacity(0.35), lineWidth: 1)
        )
    }

    private var statusDot: some View {
        ZStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            if appVM.recordingState == .recording {
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 20, height: 20)
    }

    private var statusColor: Color {
        switch appVM.recordingState {
        case .recording: return AppColors.recording
        case .processing: return AppColors.processing
        case .done: return AppColors.success
        case .error: return AppColors.warning
        case .idle: return AppColors.accent
        }
    }

    private var statusBorderColor: Color {
        switch appVM.recordingState {
        case .idle: return AppColors.border
        default: return statusColor
        }
    }

    private var statusTitle: String {
        switch appVM.recordingState {
        case .recording: return "Recording…"
        case .processing: return "Transcribing…"
        case .done: return "Done"
        case .error: return "Error"
        case .idle: return "Ready"
        }
    }

    private var statusSubtitle: String {
        switch appVM.recordingState {
        case .done(let t): return String(t.prefix(50))
        case .error(let e): return e
        case .idle: return "Waiting for hotkey"
        default: return ""
        }
    }

    private var engineBadge: some View {
        let name = EngineID(rawValue: settingsVM.selectedEngineID)?.displayName ?? "Local"
        return Text(name)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(AppColors.surface))
            .foregroundStyle(AppColors.textSecondary)
    }

    // MARK: - Shortcuts

    private var shortcutsRow: some View {
        HStack(spacing: 8) {
            if settingsVM.activationMode == .pushToTalk || settingsVM.activationMode == .both {
                ShortcutChip(label: shortcutLabel(for: .pushToTalk), description: "Hold")
            }
            if settingsVM.activationMode == .toggle || settingsVM.activationMode == .both {
                ShortcutChip(label: shortcutLabel(for: .toggleRecording), description: "Toggle")
            }
            Spacer()
        }
    }

    private func shortcutLabel(for name: KeyboardShortcuts.Name) -> String {
        KeyboardShortcuts.getShortcut(for: name)?.description ?? "Not set"
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("RECENT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)
                .tracking(0.8)
                .padding(.horizontal, 14)
                .padding(.top, 11)
                .padding(.bottom, 7)

            if appVM.lastTranscription.isEmpty {
                Text("No transcriptions yet")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            } else {
                Text(appVM.lastTranscription)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(3)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                    .onTapGesture {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(appVM.lastTranscription, forType: .string)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: 0) {
            FooterButton(title: "History", icon: "clock") {
                openHistory()
            }
            Divider()
                .frame(height: 24)
                .background(AppColors.border)
            FooterButton(title: "Settings", icon: "gear") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
        }
        .frame(height: 40)
    }

    private func openHistory() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Transcription History"
        window.center()
        window.contentViewController = NSHostingController(
            rootView: HistoryView().environmentObject(historyVM)
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Supporting Views

struct ShortcutChip: View {
    let label: String
    let description: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(AppColors.surfaceHigh))
            Text(description)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textMuted)
        }
    }
}

struct FooterButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .foregroundStyle(isHovered ? AppColors.accent : AppColors.textSecondary)
        }
        .buttonStyle(.plain)
        .background(isHovered ? AppColors.surfaceHover : AppColors.base)
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { isHovered = h } }
    }
}

extension View {
    func hoverEffect() -> some View {
        self.modifier(HoverEffectModifier())
    }
}

struct HoverEffectModifier: ViewModifier {
    @State private var hovered = false
    func body(content: Content) -> some View {
        content
            .background(hovered ? AppColors.surfaceHover : .clear)
            .onHover { hovered = $0 }
    }
}
