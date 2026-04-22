import Foundation
import WhisperKit

final class WhisperKitEngine: TranscriptionEngine, @unchecked Sendable {
    let id = EngineID.whisperKit.rawValue
    let displayName = EngineID.whisperKit.displayName
    let requiresAPIKey = false

    private var pipe: WhisperKit?
    private let modelName: String

    init(modelName: String = "openai_whisper-base") {
        self.modelName = modelName
    }

    func load() async throws {
        pipe = try await WhisperKit(model: modelName)
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let pipe else { throw TranscriptionError.modelNotLoaded }
        let results = try await pipe.transcribe(audioPath: audioURL.path)
        return results?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
