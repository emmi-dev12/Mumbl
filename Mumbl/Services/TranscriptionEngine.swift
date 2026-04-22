import Foundation

protocol TranscriptionEngine: Sendable {
    var id: String { get }
    var displayName: String { get }
    var requiresAPIKey: Bool { get }
    func transcribe(audioURL: URL) async throws -> String
}

enum TranscriptionError: LocalizedError {
    case noAPIKey
    case networkError(Error)
    case invalidResponse
    case modelNotLoaded
    case audioConversionFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "API key not configured. Add it in Settings → Cloud APIs."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .invalidResponse: return "Invalid response from transcription service."
        case .modelNotLoaded: return "Whisper model not loaded. Download it in Settings → Models."
        case .audioConversionFailed: return "Failed to process audio."
        }
    }
}

enum EngineID: String, CaseIterable {
    case whisperKit = "whisperkit"
    case openAI = "openai"
    case groq = "groq"
    case deepgram = "deepgram"

    var displayName: String {
        switch self {
        case .whisperKit: return "Local (WhisperKit)"
        case .openAI: return "OpenAI Whisper"
        case .groq: return "Groq Whisper"
        case .deepgram: return "Deepgram Nova"
        }
    }

    var requiresAPIKey: Bool { self != .whisperKit }
}
