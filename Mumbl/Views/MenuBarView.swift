import SwiftUI
import KeyboardShortcuts

struct MenuBarView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @Environment(\.openSettings) var openSettings
    @State private var showHistory = false

    var body: some View {
        ZStack {
            // Cyberpunk dark background
            CyberpunkColors.darkBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with neon styling
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title2)
                            .foregroundStyle(CyberpunkColors.neonPink)
                            .neonGlow(CyberpunkColors.neonPink, radius: 4)
                        Text("Mumbl")
                            .font(.headline)
                            .foregroundStyle(CyberpunkColors.textPrimary)
                            .neonGlow(CyberpunkColors.neonMagenta, radius: 2)
                    }
                    Spacer()
                    Button(action: { NSApp.terminate(nil) }) {
                        Image(systemName: "power")
                            .foregroundStyle(CyberpunkColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Quit Mumbl")
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Divider()
                    .background(CyberpunkColors.neonPink.opacity(0.2))

                // Status card with neon border
                statusCard
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                // Shortcuts info
                shortcutsInfo
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                Divider()
                    .background(CyberpunkColors.neonMagenta.opacity(0.2))

                // Recent transcriptions
                recentSection

                Divider()
                    .background(CyberpunkColors.neonPink.opacity(0.2))

                // Footer actions
                HStack(spacing: 0) {
                    MenuBarButton(title: "History", icon: "clock") {
                        openHistory()
                    }
                    MenuBarButton(title: "Settings", icon: "gear") {
                        NSApp.activate(ignoringOtherApps: true)
                        openSettings()
                    }
                }
                .padding(.bottom, 4)
            }
            .frame(width: 320)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            // Status indicator dot
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .neonGlow(statusColor, radius: 3)
                
                if appVM.recordingState == .recording {
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 18, height: 18)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                Text(statusSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(CyberpunkColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            engineBadge
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(CyberpunkColors.darkBgAlt)
                .stroke(borderColor, lineWidth: 1)
        )
        .neonGlow(borderColor, radius: 5)
    }

    private var borderColor: Color {
        switch appVM.recordingState {
        case .recording: return CyberpunkColors.recordingRed
        case .processing: return CyberpunkColors.processingBlue
        case .done: return CyberpunkColors.successGreen
        case .error: return CyberpunkColors.accentYellow
        case .idle: return CyberpunkColors.neonPink.opacity(0.3)
        }
    }

    private var statusColor: Color {
        switch appVM.recordingState {
        case .recording: return CyberpunkColors.recordingRed
        case .processing: return CyberpunkColors.processingBlue
        case .done: return CyberpunkColors.successGreen
        case .error: return CyberpunkColors.accentYellow
        case .idle: return CyberpunkColors.neonPink
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
        Text(EngineID(rawValue: settingsVM.selectedEngineID)?.displayName ?? "Local")
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(CyberpunkColors.neonMagenta.opacity(0.2)))
            .foregroundStyle(CyberpunkColors.neonMagenta)
            .neonGlow(CyberpunkColors.neonMagenta, radius: 2)
    }

    private var shortcutsInfo: some View {
        HStack(spacing: 12) {
            if settingsVM.activationMode == .pushToTalk || settingsVM.activationMode == .both {
                let pushToTalkLabel = shortcutString(for: .pushToTalk)
                ShortcutChip(label: pushToTalkLabel, description: "Push-to-talk")
            }
            if settingsVM.activationMode == .toggle || settingsVM.activationMode == .both {
                let toggleLabel = shortcutString(for: .toggleRecording)
                ShortcutChip(label: toggleLabel, description: "Toggle")
            }
        }
    }

    private func shortcutString(for name: KeyboardShortcuts.Name) -> String {
        guard let shortcut = KeyboardShortcuts.getShortcut(for: name) else {
            return "Not set"
        }

        return shortcut.description
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CyberpunkColors.neonCyan)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            if appVM.lastTranscription.isEmpty {
                Text("No transcriptions yet")
                    .font(.system(size: 12))
                    .foregroundStyle(CyberpunkColors.textMuted)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            } else {
                Text(appVM.lastTranscription)
                    .font(.system(size: 12))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                    .lineLimit(3)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .onTapGesture {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(appVM.lastTranscription, forType: .string)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            rootView: HistoryView()
                .environmentObject(historyVM)
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ShortcutChip: View {
    let label: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(CyberpunkColors.neonCyan)
                .neonGlow(CyberpunkColors.neonCyan, radius: 2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(CyberpunkColors.neonCyan.opacity(0.1)))
            Text(description)
                .font(.system(size: 10))
                .foregroundStyle(CyberpunkColors.textSecondary)
        }
    }
}

struct MenuBarButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(CyberpunkColors.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? CyberpunkColors.neonPink.opacity(0.15) : CyberpunkColors.darkBgAlt)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .padding(.horizontal, 4)
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
            .background(hovered ? Color.primary.opacity(0.06) : .clear)
            .onHover { hovered = $0 }
    }
}
