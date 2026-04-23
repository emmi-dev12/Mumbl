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
        case .tiny: return "Tiny (~75 MB)"
        case .base: return "Base (~145 MB)"
        case .small: return "Small (~465 MB)"
        case .medium: return "Medium (~1.5 GB)"
        case .largev3: return "Large v3 (~3 GB)"
        }
    }
}

@MainActor
final class ModelManagerService: ObservableObject {
    @Published var downloadedModels: Set<String> = []
    @Published var downloadProgress: [String: Double] = [:]

    // WhisperKit stores models under ~/Library/Caches/huggingface/hub/models/argmaxinc/
    private let whisperKitCacheBase: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appendingPathComponent("huggingface/hub/models/argmaxinc", isDirectory: true)
    }()

    init() {
        refreshDownloaded()
    }

    func isDownloaded(_ model: WhisperModelSize) -> Bool {
        downloadedModels.contains(model.rawValue)
    }

    func download(_ model: WhisperModelSize) async throws {
        await MainActor.run { downloadProgress[model.rawValue] = 0.05 }

        let config = WhisperKitConfig(model: model.rawValue, verbose: false, logLevel: .none)
        _ = try await WhisperKit(config)

        await MainActor.run {
            downloadedModels.insert(model.rawValue)
            downloadProgress.removeValue(forKey: model.rawValue)
        }
    }

    func makeEngine(for model: WhisperModelSize) -> WhisperKitEngine {
        WhisperKitEngine(modelName: model.rawValue)
    }

    func refreshDownloaded() {
        var found = Set<String>()
        for model in WhisperModelSize.allCases {
            if isModelCached(model) {
                found.insert(model.rawValue)
            }
        }
        downloadedModels = found
    }

    private func isModelCached(_ model: WhisperModelSize) -> Bool {
        // WhisperKit caches models in a path like:
        // ~/Library/Caches/huggingface/hub/models/argmaxinc/whisperkit-coreml/...
        let fm = FileManager.default
        let base = whisperKitCacheBase
        guard let contents = try? fm.contentsOfDirectory(atPath: base.path) else { return false }
        for dir in contents {
            let modelDir = base.appendingPathComponent(dir).appendingPathComponent(model.rawValue)
            if fm.fileExists(atPath: modelDir.path) {
                return true
            }
        }
        return false
    }
}
