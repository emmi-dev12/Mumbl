import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let pushToTalk = Self("pushToTalk", default: .init(.rightOption))
    static let toggleRecording = Self("toggleRecording", default: .init(.space, modifiers: [.command, .shift]))
}

@MainActor
final class HotkeyService {
    private var appVM: AppViewModel?
    private var settingsVM: SettingsViewModel?
    private var isKeyHeld = false

    func setup(appVM: AppViewModel, settingsVM: SettingsViewModel) {
        self.appVM = appVM
        self.settingsVM = settingsVM
        bindShortcuts()
    }

    private func bindShortcuts() {
        // Push-to-talk: start on keyDown, stop on keyUp
        KeyboardShortcuts.onKeyDown(for: .pushToTalk) { [weak self] in
            guard let self, let vm = self.appVM, let settings = self.settingsVM else { return }
            guard settings.activationMode == .pushToTalk || settings.activationMode == .both else { return }
            guard !self.isKeyHeld else { return }
            self.isKeyHeld = true
            Task { await vm.startRecording() }
        }

        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            guard let self, let vm = self.appVM, let settings = self.settingsVM else { return }
            guard settings.activationMode == .pushToTalk || settings.activationMode == .both else { return }
            guard self.isKeyHeld else { return }
            self.isKeyHeld = false
            Task { await vm.stopAndTranscribe() }
        }

        // Toggle: press to start, press again to stop
        KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [weak self] in
            guard let self, let vm = self.appVM, let settings = self.settingsVM else { return }
            guard settings.activationMode == .toggle || settings.activationMode == .both else { return }
            Task {
                if await vm.recordingState == .recording {
                    await vm.stopAndTranscribe()
                } else {
                    await vm.startRecording()
                }
            }
        }
    }
}
