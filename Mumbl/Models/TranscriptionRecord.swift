import SwiftData
import Foundation

@Model
final class TranscriptionRecord {
    var id: UUID
    var text: String
    var cleanedText: String?
    var date: Date
    var engineID: String
    var durationSeconds: Double

    init(text: String, engineID: String, durationSeconds: Double) {
        self.id = UUID()
        self.text = text
        self.engineID = engineID
        self.durationSeconds = durationSeconds
        self.date = Date()
    }

    var engineDisplayName: String {
        EngineID(rawValue: engineID)?.displayName ?? engineID
    }
}
