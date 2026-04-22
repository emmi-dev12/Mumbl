import SwiftUI
import Combine

enum RecordingState: Equatable {
    case idle
    case recording
    case processing
    case done(String)
    case error(String)
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var lastTranscription: String = ""
    @Published var errorMessage: String?

    private let audioService: AudioRecordingService
    private let textInsertion: TextInsertionService
    private let modelManager: ModelManagerService
    private let aiCleanup: AICleanupService

    var currentEngine: (any TranscriptionEngine)?

    init(
        audioService: AudioRecordingService,
        textInsertion: TextInsertionService,
        modelManager: ModelManagerService,
        aiCleanup: AICleanupService
    ) {
        self.audioService = audioService
        self.textInsertion = textInsertion
        self.modelManager = modelManager
        self.aiCleanup = aiCleanup
    }

    var audioLevel: Float { audioService.audioLevel }

    func startRecording() async {
        guard recordingState == .idle else { return }
        do {
            try audioService.startRecording()
            recordingState = .recording
        } catch {
            recordingState = .error(error.localizedDescription)
        }
    }

    func stopAndTranscribe() async {
        guard recordingState == .recording else { return }
        guard let audioURL = audioService.stopRecording() else {
            recordingState = .idle
            return
        }

        recordingState = .processing

        do {
            guard let engine = currentEngine else {
                throw TranscriptionError.modelNotLoaded
            }

            var text = try await engine.transcribe(audioURL: audioURL)

            // Apply AI cleanup if configured
            if let settings = currentSettings, settings.aiCleanupEnabled,
               let key = keychainKey(for: settings.aiCleanupProvider) {
                text = (try? await aiCleanup.cleanup(text, provider: settings.aiCleanupProvider, apiKey: key)) ?? text
            }

            lastTranscription = text
            recordingState = .done(text)
            textInsertion.insert(text)

            // Save to history via notification
            NotificationCenter.default.post(name: .transcriptionCompleted, object: TranscriptionResult(
                text: text,
                engineID: engine.id,
                duration: 0
            ))

            try? FileManager.default.removeItem(at: audioURL)

            // Reset to idle after brief done state
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if case .done = recordingState { recordingState = .idle }

        } catch {
            recordingState = .error(error.localizedDescription)
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            recordingState = .idle
        }
    }

    func cancelRecording() {
        _ = audioService.stopRecording()
        recordingState = .idle
    }

    // Injected by coordinator after settings are wired up
    var currentSettings: SettingsViewModel?

    private func keychainKey(for provider: AICleanupProvider) -> String? {
        switch provider {
        case .openAI: return KeychainService.shared.load(for: "openai_api_key")
        case .groq: return KeychainService.shared.load(for: "groq_api_key")
        }
    }
}

struct TranscriptionResult {
    let text: String
    let engineID: String
    let duration: Double
}

extension Notification.Name {
    static let transcriptionCompleted = Notification.Name("transcriptionCompleted")
}
