import SwiftUI
import SwiftData

@MainActor
final class AppCoordinator: ObservableObject {
    let appVM: AppViewModel
    let settingsVM: SettingsViewModel
    let historyVM: HistoryViewModel
    let modelContainer: ModelContainer

    private let audioService = AudioRecordingService()
    private let textInsertion = TextInsertionService()
    private let hotkeyService = HotkeyService()
    private let modelManager = ModelManagerService()
    private let aiCleanup = AICleanupService()

    init() {
        let container = try! ModelContainer(for: TranscriptionRecord.self)
        self.modelContainer = container
        self.settingsVM = SettingsViewModel()
        self.historyVM = HistoryViewModel(container: container)
        self.appVM = AppViewModel(
            audioService: audioService,
            textInsertion: textInsertion,
            modelManager: modelManager,
            aiCleanup: aiCleanup
        )
    }

    func start() {
        appVM.currentSettings = settingsVM
        hotkeyService.setup(appVM: appVM, settingsVM: settingsVM)
        FloatingIndicatorController.shared.setup(appVM: appVM)
        wireEngine()

        if settingsVM.isFirstLaunch {
            showOnboarding()
        }
    }

    func wireEngine() {
        let engineID = EngineID(rawValue: settingsVM.selectedEngineID) ?? .whisperKit
        switch engineID {
        case .whisperKit:
            let engine = modelManager.makeEngine(for: settingsVM.selectedModelSize)
            appVM.currentEngine = engine
            Task {
                do {
                    try await engine.load()
                } catch {
                    appVM.recordingState = .error("Failed to load Whisper model: \(error.localizedDescription)")
                }
            }
        case .openAI:
            appVM.currentEngine = OpenAIEngine(apiKey: { [weak self] in self?.settingsVM.openAIKey })
        case .groq:
            appVM.currentEngine = GroqEngine(apiKey: { [weak self] in self?.settingsVM.groqKey })
        case .deepgram:
            appVM.currentEngine = DeepgramEngine(apiKey: { [weak self] in self?.settingsVM.deepgramKey })
        }
    }

    private func showOnboarding() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Mumbl"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: OnboardingView(onComplete: { [weak self] in
                self?.settingsVM.isFirstLaunch = false
                window.close()
            })
            .environmentObject(settingsVM)
            .modelContainer(modelContainer)
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
