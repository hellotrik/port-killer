import SwiftUI
import Defaults

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as accessory (menu bar only, no Dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Initialize notification service for watched port alerts
        NotificationService.shared.setup()

        // Monitor window visibility to toggle Dock icon
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window.title == "PortKiller" else { return }
        // Show in Dock when main window is open
        NSApp.setActivationPolicy(.regular)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window.title == "PortKiller" else { return }
        // Hide from Dock when main window closes
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let appState = appState else {
            return .terminateNow
        }

        // Stop all tunnels before terminating
        Task {
            await appState.tunnelManager.stopAllTunnels()
            await MainActor.run {
                NSApp.reply(toApplicationShouldTerminate: true)
            }
        }

        return .terminateLater
    }
}

@main
struct PortKillerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var state = AppState()
    @State private var sponsorManager = SponsorManager()
    @Environment(\.openWindow) private var openWindow

    init() {
        // Disable automatic window tabbing (prevents Chrome-like tabs)
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        // Main Window - Single instance only
        Window("PortKiller", id: "main") {
            MainWindowView()
                .environment(state)
                .environment(sponsorManager)
                .task {
                    // Pass state to AppDelegate for termination handling
                    appDelegate.appState = state

                    try? await Task.sleep(for: .seconds(3))
                    sponsorManager.checkAndShowIfNeeded()
                }
                .onChange(of: sponsorManager.shouldShowWindow) { _, shouldShow in
                    if shouldShow {
                        state.selectedSidebarItem = .sponsors
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "main")
                        sponsorManager.markWindowShown()
                    }
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1000, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {} // Disable Cmd+N

        }

        // Menu Bar (quick access)
        MenuBarExtra {
            MenuBarView(state: state)
        } label: {
            Image(nsImage: menuBarIcon())
        }
        .menuBarExtraStyle(.window)
    }

    private func menuBarIcon() -> NSImage {
        // Try various bundle paths for icon
        let searchPaths: [URL?] = [
            // First try: PortKiller bundle in Resources
            Bundle.main.resourceURL?.appendingPathComponent("PortKiller_PortKiller.bundle"),
            // Second try: PortKiller bundle at app root
            Bundle.main.bundleURL.appendingPathComponent("PortKiller_PortKiller.bundle"),
            // Third try: Direct in Resources directory
            Bundle.main.resourceURL,
            // Fourth try: App root
            Bundle.main.bundleURL
        ]
        
        // Try @2x version first (Retina)
        for basePath in searchPaths {
            if let base = basePath {
                let iconPath = base.appendingPathComponent("ToolbarIcon@2x.png")
                if FileManager.default.fileExists(atPath: iconPath.path),
                   let img = NSImage(contentsOf: iconPath) {
                    img.size = NSSize(width: 18, height: 18)
                    img.isTemplate = true
                    return img
                }
            }
        }
        
        // Fallback: Try non-@2x version
        for basePath in searchPaths {
            if let base = basePath {
                let iconPath = base.appendingPathComponent("ToolbarIcon.png")
                if FileManager.default.fileExists(atPath: iconPath.path),
                   let img = NSImage(contentsOf: iconPath) {
                    img.size = NSSize(width: 18, height: 18)
                    img.isTemplate = true
                    return img
                }
            }
        }
        
        // Final fallback: Use AppIcon if available
        if let appIcon = NSImage(named: "AppIcon") {
            appIcon.size = NSSize(width: 18, height: 18)
            appIcon.isTemplate = true
            return appIcon
        }
        
        // Last resort: system icon (should not reach here if icon files exist)
        return NSImage(systemSymbolName: "network", accessibilityDescription: "PortKiller") ?? NSImage()
    }
}
