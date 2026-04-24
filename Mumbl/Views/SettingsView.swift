import SwiftUI
import KeyboardShortcuts
import AppKit

// MARK: - Settings Section

enum SettingsSection: String, CaseIterable, Hashable {
    case general, models, hotkeys, aiCleanup, cloudAPIs, about

    var label: String {
        switch self {
        case .general: return "General"
        case .models: return "Models"
        case .hotkeys: return "Hotkeys"
        case .aiCleanup: return "AI Cleanup"
        case .cloudAPIs: return "Cloud APIs"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .models: return "cpu"
        case .hotkeys: return "keyboard"
        case .aiCleanup: return "sparkles"
        case .cloudAPIs: return "cloud"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Settings Root

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @State private var selected: SettingsSection = .general

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
        } detail: {
            detail
                .environmentObject(settingsVM)
                .environmentObject(historyVM)
        }
        .frame(width: 620, height: 460)
        .preferredColorScheme(.dark)
        .navigationSplitViewStyle(.prominentDetail)
    }

    private var sidebar: some View {
        List(selection: $selected) {
            ForEach(SettingsSection.allCases, id: \.self) { section in
                SidebarRow(section: section, isSelected: selected == section)
                    .tag(section)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppColors.surface)
        .navigationSplitViewColumnWidth(min: 150, ideal: 160, max: 180)
    }

    @ViewBuilder
    private var detail: some View {
        switch selected {
        case .general: GeneralTab()
        case .models: ModelsTab()
        case .hotkeys: HotkeysTab()
        case .aiCleanup: AICleanupTab()
        case .cloudAPIs: CloudAPITab()
        case .about: AboutTab()
        }
    }
}

struct SidebarRow: View {
    let section: SettingsSection
    let isSelected: Bool

    var body: some View {
        Label(section.label, systemImage: section.icon)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isSelected ? AppColors.accent : AppColors.textSecondary)
            .padding(.vertical, 1)
    }
}

// MARK: - General Tab

struct GeneralTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsCard(title: "Activation") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mode")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                        Picker("", selection: Binding(
                            get: { settingsVM.activationMode },
                            set: { settingsVM.activationMode = $0 }
                        )) {
                            ForEach(ActivationMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                SettingsCard(title: "Floating Indicator") {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow {
                            Text("Position")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
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
                        Divider().background(AppColors.border)
                        SettingsRow {
                            Text("Show transcription preview")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Toggle("", isOn: $settingsVM.showTranscriptionInIndicator)
                                .tint(AppColors.accent)
                        }
                    }
                }

                SettingsCard(title: "Feedback") {
                    SettingsRow {
                        Text("Sound feedback")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Toggle("", isOn: $settingsVM.soundFeedbackEnabled)
                            .tint(AppColors.accent)
                    }
                }

                SettingsCard(title: "Launch") {
                    LaunchAtLoginToggle()
                }
            }
            .padding(20)
        }
        .background(AppColors.base)
    }
}

struct LaunchAtLoginToggle: View {
    @State private var enabled = false

    var body: some View {
        SettingsRow {
            Text("Launch at login")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: $enabled)
                .tint(AppColors.accent)
                .onChange(of: enabled) { _, _ in
                    // SMAppService integration would go here
                }
        }
    }
}

// MARK: - Models Tab

struct ModelsTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var modelManager: ModelManagerService
    @State private var downloadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsCard(title: "Transcription Engine") {
                    Picker("", selection: $settingsVM.selectedEngineID) {
                        ForEach(EngineID.allCases, id: \.rawValue) { engine in
                            Text(engine.displayName).tag(engine.rawValue)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                if settingsVM.selectedEngineID == EngineID.whisperKit.rawValue {
                    SettingsCard(title: "Local Model") {
                        VStack(spacing: 0) {
                            ForEach(Array(WhisperModelSize.allCases.enumerated()), id: \.element) { idx, size in
                                if idx > 0 {
                                    Divider().background(AppColors.border)
                                }
                                ModelRow(
                                    size: size,
                                    isSelected: settingsVM.selectedModelSize == size,
                                    isDownloaded: modelManager.isDownloaded(size),
                                    isDownloading: modelManager.downloadProgress[size.rawValue] != nil,
                                    progress: modelManager.downloadProgress[size.rawValue] ?? 0,
                                    onSelect: { settingsVM.selectedModelSize = size },
                                    onDownload: { download(size) }
                                )
                                .padding(.vertical, 8)
                            }
                        }
                    }

                    if let error = downloadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(AppColors.warning)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(20)
        }
        .background(AppColors.base)
        .onAppear { modelManager.refreshDownloaded() }
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

struct ModelRow: View {
    let size: WhisperModelSize
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let progress: Double
    let onSelect: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(size.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                if isDownloading {
                    ProgressView(value: progress)
                        .frame(width: 120)
                        .tint(AppColors.accent)
                }
            }
            Spacer()
            if isDownloading {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textSecondary)
            } else if isDownloaded {
                if isSelected {
                    Text("Active")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppColors.accentDim))
                        .foregroundStyle(AppColors.accent)
                } else {
                    Button("Use", action: onSelect)
                        .buttonStyle(.bordered)
                }
            } else {
                Button("Download", action: onDownload)
                    .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - AI Cleanup Tab

struct AICleanupTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsCard(title: "AI Cleanup") {
                    VStack(alignment: .leading, spacing: 10) {
                        SettingsRow {
                            Text("Enable AI cleanup")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Toggle("", isOn: $settingsVM.aiCleanupEnabled)
                                .tint(AppColors.accent)
                        }
                        Text("Removes filler words, fixes grammar, and polishes transcriptions before inserting them.")
                            .font(.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }

                if settingsVM.aiCleanupEnabled {
                    SettingsCard(title: "Provider") {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("", selection: Binding(
                                get: { settingsVM.aiCleanupProvider },
                                set: { settingsVM.aiCleanupProvider = $0 }
                            )) {
                                ForEach(AICleanupProvider.allCases, id: \.self) { provider in
                                    Text(provider.displayName).tag(provider)
                                }
                            }
                            .pickerStyle(.radioGroup)
                            Text(settingsVM.aiCleanupProvider == .local
                                ? "Runs on-device: removes filler words and cleans up punctuation."
                                : "Requires a valid API key in Cloud APIs settings.")
                                .font(.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(AppColors.base)
    }
}

// MARK: - Hotkeys Tab

struct HotkeysTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsCard(title: "Push-to-Talk") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Shortcut") {
                            KeyboardShortcuts.Recorder("", name: .pushToTalk)
                        }
                        Text("Hold to record, release to transcribe and insert.")
                            .font(.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }

                SettingsCard(title: "Toggle") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Shortcut") {
                            KeyboardShortcuts.Recorder("", name: .toggleRecording)
                        }
                        Text("Press once to start recording, press again to stop and insert.")
                            .font(.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
            .padding(20)
        }
        .background(AppColors.base)
    }
}

// MARK: - Cloud APIs Tab

struct CloudAPITab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var openAIKey = ""
    @State private var groqKey = ""
    @State private var deepgramKey = ""
    @State private var showOpenAI = false
    @State private var showGroq = false
    @State private var showDeepgram = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsCard(title: "OpenAI") {
                    APIKeyField(label: "API Key", placeholder: "sk-...",
                                value: $openAIKey, show: $showOpenAI,
                                onSave: { settingsVM.openAIKey = openAIKey })
                }
                SettingsCard(title: "Groq") {
                    APIKeyField(label: "API Key", placeholder: "gsk_...",
                                value: $groqKey, show: $showGroq,
                                onSave: { settingsVM.groqKey = groqKey })
                }
                SettingsCard(title: "Deepgram") {
                    APIKeyField(label: "API Key", placeholder: "dg_...",
                                value: $deepgramKey, show: $showDeepgram,
                                onSave: { settingsVM.deepgramKey = deepgramKey })
                }
            }
            .padding(20)
        }
        .background(AppColors.base)
        .onAppear {
            openAIKey = settingsVM.openAIKey
            groqKey = settingsVM.groqKey
            deepgramKey = settingsVM.deepgramKey
        }
    }
}

struct APIKeyField: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    @Binding var show: Bool
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if show {
                TextField(placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField(placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)
            }
            Button(show ? "Hide" : "Show") { show.toggle() }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textMuted)
            Button("Save") { onSave() }
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - About Tab

struct AboutTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsCard(title: "") {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 48))
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
                }

                SettingsCard(title: "Getting Started") {
                    Button("Show Onboarding") {
                        let window = NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
                            styleMask: [.titled, .closable],
                            backing: .buffered,
                            defer: false
                        )
                        window.title = "Welcome to Mumbl"
                        window.center()
                        window.contentViewController = NSHostingController(
                            rootView: OnboardingView(onComplete: { window.close() })
                                .environmentObject(settingsVM)
                        )
                        window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    .buttonStyle(.bordered)
                }

                SettingsCard(title: "Updates") {
                    VStack(spacing: 12) {
                        SettingsRow {
                            Text("Auto-update")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Toggle("", isOn: $settingsVM.autoUpdateEnabled)
                                .tint(AppColors.accent)
                        }
                        if settingsVM.autoUpdateEnabled {
                            Divider().background(AppColors.border)
                            Picker("Check frequency", selection: Binding(
                                get: { settingsVM.updateCheckInterval },
                                set: { settingsVM.updateCheckInterval = $0 }
                            )) {
                                ForEach(UpdateCheckInterval.allCases, id: \.self) { interval in
                                    Text(interval.displayName).tag(interval)
                                }
                            }
                            .pickerStyle(.radioGroup)
                        }
                        Divider().background(AppColors.border)
                        Button("Check for Updates Now") {
                            NSApp.sendAction(Selector(("checkForUpdates:")), to: nil, from: nil)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                SettingsCard(title: "Links") {
                    VStack(alignment: .leading, spacing: 8) {
                        Link("GitHub", destination: URL(string: "https://github.com/emmi-dev12/mumbl")!)
                            .foregroundStyle(AppColors.accent)
                        Link("Report Issue", destination: URL(string: "https://github.com/emmi-dev12/mumbl/issues")!)
                            .foregroundStyle(AppColors.accent)
                    }
                }

                Text("MIT License · Made with Swift")
                    .font(.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
        }
        .background(AppColors.base)
    }
}

// MARK: - Shared Components

struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !title.isEmpty {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
                    .tracking(0.8)
            }
            content
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.surfaceHigh)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack { content }
    }
}
