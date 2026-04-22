import SwiftUI
import AppKit
import Sparkle

@main
struct MumblApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.coordinator.settingsVM)
                .environmentObject(appDelegate.coordinator.historyVM)
                .modelContainer(appDelegate.coordinator.modelContainer)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    let coordinator = AppCoordinator()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        coordinator.start()
        setupUpdater()
    }

    private func setupUpdater() {
        updater.updater.delegate = self
        if UserDefaults.standard.bool(forKey: "autoUpdateEnabled") {
            updater.updater.checkForUpdatesInBackground()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Mumbl")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        let pop = NSPopover()
        pop.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(coordinator.appVM)
                .environmentObject(coordinator.settingsVM)
                .environmentObject(coordinator.historyVM)
                .modelContainer(coordinator.modelContainer)
        )
        pop.behavior = .transient
        pop.contentSize = NSSize(width: 320, height: 420)
        popover = pop
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
