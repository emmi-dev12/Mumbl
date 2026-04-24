import SwiftUI
import AppKit
import Sparkle

@main
struct MumblApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Mumbl", id: "main") {
            MainWindowView()
                .environmentObject(appDelegate.coordinator.appVM)
                .environmentObject(appDelegate.coordinator.settingsVM)
                .environmentObject(appDelegate.coordinator.historyVM)
                .environmentObject(appDelegate.coordinator.modelManager)
                .modelContainer(appDelegate.coordinator.modelContainer)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 960, height: 660)
        .defaultPosition(.center)
        .commands {
            // Remove default Settings menu item since settings are inside the main window
            CommandGroup(replacing: .appSettings) { }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    let coordinator = AppCoordinator()
    private var statusItem: NSStatusItem?
    private let updater = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        coordinator.start()
        setupUpdater()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func setupUpdater() {
        if UserDefaults.standard.bool(forKey: "autoUpdateEnabled") {
            updater.updater.checkForUpdatesInBackground()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Mumbl")
            button.image?.isTemplate = true
            button.action = #selector(openMainWindow)
            button.target = self
        }
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.makeKeyAndOrderFront(nil)
            return
        }
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}
