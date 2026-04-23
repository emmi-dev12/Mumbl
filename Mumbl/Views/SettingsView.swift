import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel

    var body: some View {
        ZStack {
            // Cyberpunk dark background
            CyberpunkColors.darkBg
                .ignoresSafeArea()
            
            TabView {
                GeneralTab()
                    .tabItem { Label("General", systemImage: "gear") }

                ModelsTab()
                    .tabItem { Label("Models", systemImage: "cpu") }

                AICleanupTab()
                    .tabItem { Label("AI Cleanup", systemImage: "sparkles") }

                HotkeysTab()
                    .tabItem { Label("Hotkeys", systemImage: "keyboard") }

                CloudAPITab()
                    .tabItem { Label("Cloud APIs", systemImage: "cloud") }

                AboutTab()
                    .tabItem { Label("About", systemImage: "info.circle") }
            }
            .frame(width: 520, height: 450)
            .environmentObject(settingsVM)
            .environmentObject(historyVM)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - General Tab

struct GeneralTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        ZStack {
            CyberpunkColors.darkBg.ignoresSafeArea()
            
            Form {
                Section("Activation", content: {
                    Picker("Mode", selection: Binding(
                        get: { settingsVM.activationMode },
                        set: { settingsVM.activationMode = $0 }
                    )) {
                        ForEach(ActivationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                                .foregroundStyle(CyberpunkColors.textPrimary)
                        }
                    }
                    .pickerStyle(.segmented)
                })

                Section("🎤 Floating Indicator", content: {
                    Picker("Position", selection: Binding(
                        get: { settingsVM.indicatorPosition },
                        set: { settingsVM.indicatorPosition = $0 }
                    )) {
                        ForEach(IndicatorPosition.allCases, id: \.self) { pos in
                            Text(pos.displayName)
                                .tag(pos)
                                .foregroundStyle(CyberpunkColors.textPrimary)
                        }
                    }
                    Toggle("Show transcription preview", isOn: $settingsVM.showTranscriptionInIndicator)
                        .tint(CyberpunkColors.neonPink)
                })

                Section("Feedback", content: {
                    Toggle("Sound feedback", isOn: $settingsVM.soundFeedbackEnabled)
                        .tint(CyberpunkColors.neonPink)
                })

                Section("Launch", content: {
                    LaunchAtLoginToggle()
                })
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
    }
}

struct LaunchAtLoginToggle: View {
    @State private var enabled = false

    var body: some View {
        Toggle("Launch at login", isOn: $enabled)
            .tint(CyberpunkColors.neonPink)
            .onChange(of: enabled) { _, new in
                // SMAppService integration would go here
            }
    }
}

// MARK: - Models Tab

struct ModelsTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var modelManager: ModelManagerService
    @State private var downloadError: String?

    var body: some View {
        ZStack {
            CyberpunkColors.darkBg.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Form {
                    Section("Transcription Engine") {
                        Picker("Engine", selection: $settingsVM.selectedEngineID) {
                            ForEach(EngineID.allCases, id: \.rawValue) { engine in
                                Text(engine.displayName)
                                    .tag(engine.rawValue)
                                    .foregroundStyle(CyberpunkColors.textPrimary)
                            }
                        }
                    }

                    if settingsVM.selectedEngineID == EngineID.whisperKit.rawValue {
                        Section("🧠 Local Model") {
                            ForEach(WhisperModelSize.allCases) { size in
                                ModelRow(
                                    size: size,
                                    isSelected: settingsVM.selectedModelSize == size,
                                    isDownloaded: modelManager.isDownloaded(size),
                                    isDownloading: modelManager.downloadProgress[size.rawValue] != nil,
                                    progress: modelManager.downloadProgress[size.rawValue] ?? 0,
                                    onSelect: { settingsVM.selectedModelSize = size },
                                    onDownload: { download(size) }
                                )
                            }
                        }
                        if let error = downloadError {
                            Section {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(CyberpunkColors.accentYellow)
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
            .padding()
            .onAppear { modelManager.refreshDownloaded() }
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
            VStack(alignment: .leading, spacing: 2) {
                Text(size.displayName)
                    .font(.body)
                    .foregroundStyle(CyberpunkColors.textPrimary)
                if isDownloading {
                    ProgressView(value: progress)
                        .frame(width: 120)
                        .tint(CyberpunkColors.neonMagenta)
                }
            }
            Spacer()
            if isDownloading {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(CyberpunkColors.textSecondary)
            } else if isDownloaded {
                if isSelected {
                    Text("Active")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(CyberpunkColors.neonPink.opacity(0.2)))
                        .foregroundStyle(CyberpunkColors.neonPink)
                        .neonGlow(CyberpunkColors.neonPink, radius: 4)
                } else {
                    Button("Use", action: onSelect)
                        .buttonStyle(.bordered)
                        .tint(CyberpunkColors.neonMagenta)
                }
            } else {
                Button("Download", action: onDownload)
                    .buttonStyle(.bordered)
                    .tint(CyberpunkColors.neonMagenta)
            }
        }
    }
}

// MARK: - AI Cleanup Tab

struct AICleanupTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Enable AI cleanup", isOn: $settingsVM.aiCleanupEnabled)
                Text("Removes filler words, fixes grammar, and polishes transcriptions before inserting them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if settingsVM.aiCleanupEnabled {
                Section("Provider") {
                    Picker("Provider", selection: Binding(
                        get: { settingsVM.aiCleanupProvider },
                        set: { settingsVM.aiCleanupProvider = $0 }
                    )) {
                        ForEach(AICleanupProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    if settingsVM.aiCleanupProvider != .local {
                        Text("Requires a valid API key in Cloud APIs settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Runs on-device: removes filler words and cleans up punctuation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Hotkeys Tab

struct HotkeysTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        Form {
            Section("Push-to-Talk") {
                LabeledContent("Shortcut") {
                    KeyboardShortcuts.Recorder("", name: .pushToTalk)
                }
                Text("Hold to record, release to transcribe and insert.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Toggle") {
                LabeledContent("Shortcut") {
                    KeyboardShortcuts.Recorder("", name: .toggleRecording)
                }
                Text("Press once to start recording, press again to stop and insert.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
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
        Form {
            Section("OpenAI") {
                APIKeyField(
                    label: "API Key",
                    placeholder: "sk-...",
                    value: $openAIKey,
                    show: $showOpenAI,
                    onSave: { settingsVM.openAIKey = openAIKey }
                )
            }

            Section("Groq") {
                APIKeyField(
                    label: "API Key",
                    placeholder: "gsk_...",
                    value: $groqKey,
                    show: $showGroq,
                    onSave: { settingsVM.groqKey = groqKey }
                )
            }

            Section("Deepgram") {
                APIKeyField(
                    label: "API Key",
                    placeholder: "dg_...",
                    value: $deepgramKey,
                    show: $showDeepgram,
                    onSave: { settingsVM.deepgramKey = deepgramKey }
                )
            }
        }
        .formStyle(.grouped)
        .padding()
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
        HStack {
            if show {
                TextField(placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField(placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)
            }
            Button(show ? "Hide" : "Show") { show.toggle() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            Button("Save") { onSave() }
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - About Tab

struct AboutTab: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)
                    .frame(maxWidth: .infinity)
                Text("Mumbl")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity)
                Text("Free, open-source voice dictation for macOS.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            Section("Updates") {
                Toggle("Auto-update", isOn: $settingsVM.autoUpdateEnabled)
                if settingsVM.autoUpdateEnabled {
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
                Button("Check for Updates Now") {
                    // Sparkle will handle the check
                    NSApp.sendAction(Selector(("checkForUpdates:")), to: nil, from: nil)
                }
                .buttonStyle(.bordered)
            }

            Section("Links") {
                Link("GitHub", destination: URL(string: "https://github.com/emmi-dev12/mumbl")!)
                Link("Report Issue", destination: URL(string: "https://github.com/emmi-dev12/mumbl/issues")!)
            }

            Section {
                Text("MIT License · Made with Swift")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
