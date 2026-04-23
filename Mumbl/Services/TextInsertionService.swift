import AppKit
import Carbon

final class TextInsertionService {
    func insert(_ text: String) {
        guard !text.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        let items = pasteboard.pasteboardItems ?? []
        let savedContents: [(NSPasteboard.PasteboardType, Data)] = items.compactMap { item in
            guard let type = item.types.first, let data = item.data(forType: type) else { return nil }
            return (type, data)
        }

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        sendPasteKeystroke()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            pasteboard.clearContents()
            if let saved = savedContents, !saved.isEmpty {
                saved.forEach { type, data in
                    pasteboard.setData(data, forType: type)
                }
            }
        }
    }

    private func sendPasteKeystroke() {
        let source = CGEventSource(stateID: .combinedSessionState)

        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vKeyDown?.flags = .maskCommand
        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vKeyUp?.flags = .maskCommand

        vKeyDown?.post(tap: .cgAnnotatedSessionEventTap)
        vKeyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
