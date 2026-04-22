import SwiftUI
import SwiftData
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var searchText: String = ""
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container

        NotificationCenter.default.addObserver(
            forName: .transcriptionCompleted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let result = notification.object as? TranscriptionResult else { return }
            Task { @MainActor in
                self?.save(result)
            }
        }
    }

    private func save(_ result: TranscriptionResult) {
        let record = TranscriptionRecord(
            text: result.text,
            engineID: result.engineID,
            durationSeconds: result.duration
        )
        container.mainContext.insert(record)
        try? container.mainContext.save()
    }

    func delete(_ record: TranscriptionRecord) {
        container.mainContext.delete(record)
        try? container.mainContext.save()
    }

    func deleteAll() {
        try? container.mainContext.delete(model: TranscriptionRecord.self)
        try? container.mainContext.save()
    }
}
