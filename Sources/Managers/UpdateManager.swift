import Foundation
import Sparkle
import AppKit
import Observation
import Combine

/**
 * UpdateManager handles automatic updates using the Sparkle framework.
 *
 * Key features:
 * - Lazy initialization (2 second delay to reduce launch memory)
 * - Only initializes when running from .app bundle (not during development)
 * - Activates app before showing update UI (important for menu bar apps)
 * - Tracks update availability and last check date
 *
 * This class uses the @Observable macro for SwiftUI reactivity and is
 * marked with @MainActor to ensure all UI updates happen on the main thread.
 */
@Observable
@MainActor
final class UpdateManager {
    // MARK: - Public Properties

    /// Whether the updater is ready to check for updates
    var canCheckForUpdates = false

    /// Timestamp of the last update check
    var lastUpdateCheckDate: Date?

    // MARK: - Private Properties

    /// Sparkle updater controller instance
    private var updaterController: SPUStandardUpdaterController?

    /// Tracks whether Sparkle has been initialized
    private var isInitialized = false

    /// Check if running from a proper app bundle (not swift run)
    private static var isRunningFromBundle: Bool {
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    // MARK: - Computed Properties

    /**
     * Whether to automatically check for updates on launch.
     * Setting this value will trigger Sparkle initialization if needed.
     */
    var automaticallyChecksForUpdates: Bool {
        get { updaterController?.updater.automaticallyChecksForUpdates ?? false }
        set {
            ensureInitialized()
            updaterController?.updater.automaticallyChecksForUpdates = newValue
        }
    }

    /**
     * Whether to automatically download updates in the background.
     * Setting this value will trigger Sparkle initialization if needed.
     */
    var automaticallyDownloadsUpdates: Bool {
        get { updaterController?.updater.automaticallyDownloadsUpdates ?? false }
        set {
            ensureInitialized()
            updaterController?.updater.automaticallyDownloadsUpdates = newValue
        }
    }

    // MARK: - Initialization

    /**
     * Initializes the update manager.
     * Updates are disabled - Sparkle will not be initialized.
     */
    init() {
        // Updates are disabled - do not initialize Sparkle
    }

    // MARK: - Private Methods

    /**
     * Ensures Sparkle is initialized before use.
     * Updates are disabled - this method does nothing.
     */
    private func ensureInitialized() {
        // Updates are disabled - do not initialize Sparkle
        return
    }

    /// Storage for Combine cancellables
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []

    // MARK: - Public Methods

    /**
     * Manually checks for updates.
     * Updates are disabled - this method does nothing.
     */
    func checkForUpdates() {
        // Updates are disabled
        return
    }
}
