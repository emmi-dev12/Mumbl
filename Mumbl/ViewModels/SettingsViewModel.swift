import SwiftUI
import Combine

enum ActivationMode: String, CaseIterable {
    case pushToTalk = "pushToTalk"
    case toggle = "toggle"
    case both = "both"

    var displayName: String {
        switch self {
        case .pushToTalk: return "Push-to-Talk"
        case .toggle: return "Toggle"
        case .both: return "Both"
        }
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    @AppStorage("activationMode") private var activationModeRaw: String = ActivationMode.both.rawValue
    @AppStorage("selectedEngineID") var selectedEngineID: String = EngineID.whisperKit.rawValue
    @AppStorage("selectedModelSize") var selectedModelSizeRaw: String = WhisperModelSize.base.rawValue
    @AppStorage("aiCleanupEnabled") var aiCleanupEnabled: Bool = false
    @AppStorage("aiCleanupProviderRaw") private var aiCleanupProviderRaw: String = AICleanupProvider.local.rawValue
    @AppStorage("indicatorPosition") private var indicatorPositionRaw: String = IndicatorPosition.topCenter.rawValue
    @AppStorage("soundFeedbackEnabled") var soundFeedbackEnabled: Bool = true
    @AppStorage("showTranscriptionInIndicator") var showTranscriptionInIndicator: Bool = true
    @AppStorage("autoUpdateEnabled") var autoUpdateEnabled: Bool = true
    @AppStorage("updateCheckInterval") private var updateCheckIntervalRaw: String = UpdateCheckInterval.hourly.rawValue

    var updateCheckInterval: UpdateCheckInterval {
        get { UpdateCheckInterval(rawValue: updateCheckIntervalRaw) ?? .hourly }
        set { updateCheckIntervalRaw = newValue.rawValue }
    }

    var activationMode: ActivationMode {
        get { ActivationMode(rawValue: activationModeRaw) ?? .both }
        set { activationModeRaw = newValue.rawValue }
    }

    var selectedModelSize: WhisperModelSize {
        get { WhisperModelSize(rawValue: selectedModelSizeRaw) ?? .base }
        set { selectedModelSizeRaw = newValue.rawValue }
    }

    var aiCleanupProvider: AICleanupProvider {
        get { AICleanupProvider(rawValue: aiCleanupProviderRaw) ?? .openAI }
        set { aiCleanupProviderRaw = newValue.rawValue }
    }

    var indicatorPosition: IndicatorPosition {
        get { IndicatorPosition(rawValue: indicatorPositionRaw) ?? .topCenter }
        set { indicatorPositionRaw = newValue.rawValue }
    }

    // API keys (Keychain-backed)
    var openAIKey: String {
        get { KeychainService.shared.load(for: "openai_api_key") ?? "" }
        set {
            if newValue.isEmpty { KeychainService.shared.delete(for: "openai_api_key") }
            else { KeychainService.shared.save(newValue, for: "openai_api_key") }
        }
    }

    var groqKey: String {
        get { KeychainService.shared.load(for: "groq_api_key") ?? "" }
        set {
            if newValue.isEmpty { KeychainService.shared.delete(for: "groq_api_key") }
            else { KeychainService.shared.save(newValue, for: "groq_api_key") }
        }
    }

    var deepgramKey: String {
        get { KeychainService.shared.load(for: "deepgram_api_key") ?? "" }
        set {
            if newValue.isEmpty { KeychainService.shared.delete(for: "deepgram_api_key") }
            else { KeychainService.shared.save(newValue, for: "deepgram_api_key") }
        }
    }
}

enum IndicatorPosition: String, CaseIterable {
    case topLeft = "topLeft"
    case topCenter = "topCenter"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomCenter = "bottomCenter"
    case bottomRight = "bottomRight"
    case center = "center"
    case nearCursor = "nearCursor"

    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        case .center: return "Center"
        case .nearCursor: return "Near Cursor"
        }
    }
}

enum UpdateCheckInterval: String, CaseIterable {
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case manual = "manual"

    var displayName: String {
        switch self {
        case .hourly: return "Every hour"
        case .daily: return "Every day"
        case .weekly: return "Every week"
        case .manual: return "Manual only"
        }
    }

    var seconds: Int {
        switch self {
        case .hourly: return 3600
        case .daily: return 86400
        case .weekly: return 604800
        case .manual: return Int.max
        }
    }
}
