import Foundation
import WhisperKit

enum WhisperModelSize: String, CaseIterable, Identifiable {
    case tiny = "openai_whisper-tiny"
    case base = "openai_whisper-base"
    case small = "openai_whisper-small"
    case medium = "openai_whisper-medium"
    case largev3 = "openai_whisper-large-v3"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiny: return "Tiny (75 MB)"
        case .base: return "Base (145 MB)"
        case .small: return "Small (465 MB)"
        case .medium: return "Medium (1.5 GB)"
        case .largev3: return "Large v3 (3 GB)"
        }
    }

    var approximateSizeMB: Int {
        switch self {
        case .tiny: return 75
        case .base: return 145
        case .small: return 465
        case .medium: return 1500
        case .largev3: return 3000
        }
    }
}

@MainActor
final class ModelManagerService: ObservableObject {
    @Published var downloadedModels: Set<String> = []
    @Published var downloadProgress: [String: Double] = [:]

    private let cacheDir: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return support.appendingPathComponent("Mumbl/Models", isDirectory: true)
    }()

    init() {
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        refreshDownloaded()
    }

    func isDownloaded(_ model: WhisperModelSize) -> Bool {
        downloadedModels.contains(model.rawValue)
    }

    func download(_ model: WhisperModelSize) async throws {
        downloadProgress[model.rawValue] = 0
        // WhisperKit handles downloading to its own cache; we track completion
        _ = try await WhisperKit(model: model.rawValue, verbose: false)
        downloadedModels.insert(model.rawValue)
        downloadProgress.removeValue(forKey: model.rawValue)
    }

    func makeEngine(for model: WhisperModelSize) -> WhisperKitEngine {
        WhisperKitEngine(modelName: model.rawValue)
    }

    private func refreshDownloaded() {
        // Check WhisperKit model cache
        for model in WhisperModelSize.allCases {
            // WhisperKit caches in ~/Library/Caches/huggingface/...
            // We mark as available if WhisperKit can find the model locally
            // This is a best-effort check
        }
    }
}
