import SwiftUI
import KeyboardShortcuts
import AppKit

// MARK: - Settings Sheet Sections

enum SettingsSheetSection: String, CaseIterable, Hashable {
    case transcription, hotkeys, preferences, about

    var title: String {
        switch self {
        case .transcription: return "Transcription"
        case .hotkeys:       return "Hotkeys"
        case .preferences:   return "Preferences"
        case .about:         return "About"
        }
    }

    var icon: String {
        switch self {
        case .transcription: return "waveform"
        case .hotkeys:       return "keyboard"
        case .preferences:   return "slider.horizontal.3"
        case .about:         return "info.circle"
        }
    }
}

// MARK: - Settings Sheet (modal, shown as .sheet)

struct SettingsSheetView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var modelManager: ModelManagerService
    @Environment(\.dismiss) var dismiss
    @State private var selected: SettingsSheetSection = .transcription

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar
            Divider().background(AppColors.border)
            settingsContent
        }
        .frame(width: 700, height: 480)
        .background(AppColors.base)
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)

            VStack(spacing: 2) {
                ForEach(SettingsSheetSection.allCases, id: \.self) { section in
                    SettingsNavItem(
                        icon: section.icon,
                        title: section.title,
                        isSelected: selected == section
                    ) {
                        selected = section
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textMuted)
                    .padding(16)
            }
        }
        .frame(width: 200)
        .background(AppColors.base)
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                        .padding(6)
                        .background(Circle().fill(AppColors.surfaceHigh))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selected {
                    case .transcription: TranscriptionContent()
                    case .hotkeys:       HotkeysContent()
                    case .preferences:   PreferencesContent()
                    case .about:         AboutContent()
                    }
                }
                .padding(20)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface)
    }
}

struct SettingsNavItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.accent)
                            .frame(width: 28, height: 28)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? Color.black : AppColors.textMuted)
                }
                .frame(width: 28, height: 28)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered && !isSelected ? AppColors.surfaceHover : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Settings Row Helpers

struct SettingsItemRow<Control: View>: View {
    let icon: String
    let title: String
    let description: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                if !description.isEmpty {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                }
            }

            Spacer()
            control
        }
        .padding(14)
    }
}

struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.surfaceHigh))
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(AppColors.border)
            .padding(.horizontal, 14)
    }
}

// MARK: - Transcription Settings

struct TranscriptionContent: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var modelManager: ModelManagerService
    @State private var downloadError: String?
    @State private var openAIKey = ""
    @State private var groqKey = ""
    @State private var deepgramKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsGroup {
                SettingsItemRow(
                    icon: "cpu",
                    title: "Engine",
                    description: "Choose your transcription backend"
                ) {
                    Picker("", selection: $settingsVM.selectedEngineID) {
                        ForEach(EngineID.allCases, id: \.rawValue) { e in
                            Text(e.displayName).tag(e.rawValue)
                        }
                    }
                    .frame(width: 180)
                }
            }

            if settingsVM.selectedEngineID == EngineID.whisperKit.rawValue {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LOCAL MODEL")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.7)
                        .foregroundStyle(AppColors.textMuted)

                    SettingsGroup {
                        ForEach(Array(WhisperModelSize.allCases.enumerated()), id: \.element) { idx, size in
                            if idx > 0 { SettingsDivider() }
                            ModelRow(
                                size: size,
                                isSelected: settingsVM.selectedModelSize == size,
                                isDownloaded: modelManager.isDownloaded(size),
                                isDownloading: modelManager.downloadProgress[size.rawValue] != nil,
                                progress: modelManager.downloadProgress[size.rawValue] ?? 0,
                                onSelect: { settingsVM.selectedModelSize = size },
                                onDownload: { download(size) }
                            )
                            .padding(14)
                        }
                    }

                    if let error = downloadError {
                        Text(error).font(.caption).foregroundStyle(AppColors.warning)
                    }
                }
            }

            if settingsVM.selectedEngineID != EngineID.whisperKit.rawValue {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API KEY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.7)
                        .foregroundStyle(AppColors.textMuted)

                    SettingsGroup {
                        if settingsVM.selectedEngineID == EngineID.openAI.rawValue {
                            APIKeyRow(label: "OpenAI", placeholder: "sk-...", key: $openAIKey) {
                                settingsVM.openAIKey = openAIKey
                            }
                        } else if settingsVM.selectedEngineID == EngineID.groq.rawValue {
                            APIKeyRow(label: "Groq", placeholder: "gsk_...", key: $groqKey) {
                                settingsVM.groqKey = groqKey
                            }
                        } else if settingsVM.selectedEngineID == EngineID.deepgram.rawValue {
                            APIKeyRow(label: "Deepgram", placeholder: "dg_...", key: $deepgramKey) {
                                settingsVM.deepgramKey = deepgramKey
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            openAIKey = settingsVM.openAIKey
            groqKey = settingsVM.groqKey
            deepgramKey = settingsVM.deepgramKey
        }
    }

    private func download(_ size: WhisperModelSize) {
        downloadError = nil
        Task {
            do {
                try await modelManager.download(size)
                settingsVM.selectedModelSize = size
            } catch {
                downloadError = "Download failed: \(error.localizedDescription)"
            }
        }
    }
}

struct APIKeyRow: View {
    let label: String
    let placeholder: String
    @Binding var key: String
    let onSave: () -> Void
    @State private var show = false

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 70, alignment: .leading)
            if show {
                TextField(placeholder, text: $key)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField(placeholder, text: $key)
                    .textFieldStyle(.roundedBorder)
            }
            Button(show ? "Hide" : "Show") { show.toggle() }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)
            Button("Save") { onSave() }
                .buttonStyle(.bordered)
        }
        .padding(14)
    }
}

// MARK: - Hotkeys Settings

struct HotkeysContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsGroup {
                SettingsItemRow(
                    icon: "hand.point.right.fill",
                    title: "Push-to-Talk",
                    description: "Hold to record, release to insert"
                ) {
                    KeyboardShortcuts.Recorder("", name: .pushToTalk)
                }
                SettingsDivider()
                SettingsItemRow(
                    icon: "arrow.2.squarepath",
                    title: "Toggle Recording",
                    description: "Press to start, press again to insert"
                ) {
                    KeyboardShortcuts.Recorder("", name: .toggleRecording)
                }
            }
        }
    }
}

// MARK: - Preferences Settings

struct PreferencesContent: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsGroup {
                SettingsItemRow(
                    icon: "pip",
                    title: "Indicator Position",
                    description: "Where the floating status pill appears"
                ) {
                    Picker("", selection: Binding(
                        get: { settingsVM.indicatorPosition },
                        set: { settingsVM.indicatorPosition = $0 }
                    )) {
                        ForEach(IndicatorPosition.allCases, id: \.self) { pos in
                            Text(pos.displayName).tag(pos)
                        }
                    }
                    .frame(width: 140)
                }
                SettingsDivider()
                SettingsItemRow(
                    icon: "eye",
                    title: "Show preview in indicator",
                    description: "Display transcription text in the pill"
                ) {
                    Toggle("", isOn: $settingsVM.showTranscriptionInIndicator)
                        .tint(AppColors.accent)
                }
                SettingsDivider()
                SettingsItemRow(
                    icon: "speaker.wave.2",
                    title: "Sound feedback",
                    description: "Play sounds on start/stop"
                ) {
                    Toggle("", isOn: $settingsVM.soundFeedbackEnabled)
                        .tint(AppColors.accent)
                }
            }

            SettingsGroup {
                SettingsItemRow(
                    icon: "sparkles",
                    title: "AI Cleanup",
                    description: "Automatically fix grammar and remove filler words"
                ) {
                    Toggle("", isOn: $settingsVM.aiCleanupEnabled)
                        .tint(AppColors.accent)
                }
                if settingsVM.aiCleanupEnabled {
                    SettingsDivider()
                    SettingsItemRow(
                        icon: "cloud",
                        title: "Cleanup Provider",
                        description: ""
                    ) {
                        Picker("", selection: Binding(
                            get: { settingsVM.aiCleanupProvider },
                            set: { settingsVM.aiCleanupProvider = $0 }
                        )) {
                            ForEach(AICleanupProvider.allCases, id: \.self) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                        .frame(width: 140)
                    }
                }
            }

            SettingsGroup {
                SettingsItemRow(
                    icon: "arrow.down.circle",
                    title: "Auto-update",
                    description: "Check for updates automatically"
                ) {
                    Toggle("", isOn: $settingsVM.autoUpdateEnabled)
                        .tint(AppColors.accent)
                }
            }
        }
    }
}

// MARK: - About Settings

struct AboutContent: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsGroup {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppColors.accent)
                    Text("Mumbl")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Free, open-source voice dictation for macOS.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            }

            SettingsGroup {
                SettingsItemRow(
                    icon: "arrow.clockwise",
                    title: "Check for Updates",
                    description: ""
                ) {
                    Button("Check Now") {
                        NSApp.sendAction(Selector(("checkForUpdates:")), to: nil, from: nil)
                    }
                    .buttonStyle(.bordered)
                }
                SettingsDivider()
                SettingsItemRow(
                    icon: "star",
                    title: "Show Onboarding",
                    description: "Replay the welcome walkthrough"
                ) {
                    Button("Open") { showOnboarding() }
                        .buttonStyle(.bordered)
                }
                SettingsDivider()
                SettingsItemRow(icon: "link", title: "GitHub", description: "") {
                    Link("Open", destination: URL(string: "https://github.com/emmi-dev12/mumbl")!)
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private func showOnboarding() {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "Welcome to Mumbl"
        w.center()
        w.contentViewController = NSHostingController(
            rootView: OnboardingView(onComplete: { w.close() })
                .environmentObject(settingsVM)
        )
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Legacy wrapper (keeps Settings scene working if still used)
struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var modelManager: ModelManagerService

    var body: some View {
        SettingsSheetView()
            .environmentObject(settingsVM)
            .environmentObject(historyVM)
            .environmentObject(modelManager)
    }
}
