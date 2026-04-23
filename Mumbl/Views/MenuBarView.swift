import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @Environment(\.openSettings) var openSettings
    @State private var showHistory = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("Mumbl")
                    .font(.headline)
                Spacer()
                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "power")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit Mumbl")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            // Status card
            statusCard
                .padding(.horizontal, 12)
                .padding(.top, 10)

            // Shortcuts info
            shortcutsInfo
                .padding(.horizontal, 16)
                .padding(.top, 10)

            Divider().padding(.top, 10)

            // Recent transcriptions
            recentSection

            Divider()

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

    private var statusCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 13, weight: .medium))
                Text(statusSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            engineBadge
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(.quinary))
    }

    private var statusColor: Color {
        switch appVM.recordingState {
        case .recording: return .red
        case .processing: return .orange
        case .done: return .green
        case .error: return .orange
        case .idle: return .green
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
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(.purple.opacity(0.15)))
            .foregroundStyle(.purple)
    }

    private var shortcutsInfo: some View {
        HStack(spacing: 12) {
            if settingsVM.activationMode == .pushToTalk || settingsVM.activationMode == .both {
                ShortcutChip(label: "Hold ⌥ Right", description: "Push-to-talk")
            }
            if settingsVM.activationMode == .toggle || settingsVM.activationMode == .both {
                ShortcutChip(label: "⌘⇧Space", description: "Toggle")
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            if appVM.lastTranscription.isEmpty {
                Text("No transcriptions yet")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            } else {
                Text(appVM.lastTranscription)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
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
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(.quaternary))
            Text(description)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

struct MenuBarButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .contentShape(Rectangle())
        .hoverEffect()
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
