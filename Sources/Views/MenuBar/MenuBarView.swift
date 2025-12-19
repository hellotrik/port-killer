/// MenuBarView - Main menu bar dropdown interface
///
/// Displays the list of active ports in a compact menu bar dropdown.
/// Supports both list and tree view modes for port organization.
///
/// - Note: This view is shown when clicking the menu bar icon.
/// - Important: Uses `@Bindable var state: AppState` for state management.

import SwiftUI
import Defaults

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var state: AppState
    @State private var searchText = ""
    @State private var confirmingKillAll = false
    @State private var confirmingKillPort: UUID?
    @State private var hoveredPort: UUID?
    @State private var expandedProcesses: Set<Int> = []
    @Default(.useTreeView) private var useTreeView
    @State private var cachedGroups: [ProcessGroup] = []

    private var groupedByProcess: [ProcessGroup] { cachedGroups }

    /// Updates cached process groups from filtered ports
    /// Groups are identified by PID to ensure each process group is unique
    private func updateGroupedByProcess() {
        // Group by PID to ensure each process is uniquely identified
        let grouped = Dictionary(grouping: filteredPorts) { $0.pid }
        
        // Build a map of process name -> ports -> PIDs to identify related processes
        var processPortMap: [String: [Int: Set<Int>]] = [:]
        for port in filteredPorts {
            let portKey = port.port
            if processPortMap[port.processName] == nil {
                processPortMap[port.processName] = [:]
            }
            if processPortMap[port.processName]?[portKey] == nil {
                processPortMap[port.processName]?[portKey] = []
            }
            processPortMap[port.processName]?[portKey]?.insert(port.pid)
        }
        
        cachedGroups = grouped.map { pid, ports in
            // Remove duplicates within each group (same port + address)
            var uniquePorts: [PortInfo] = []
            var seenPorts: Set<String> = []
            for port in ports {
                let key = "\(port.port)-\(port.address)"
                if seenPorts.insert(key).inserted {
                    uniquePorts.append(port)
                }
            }
            
            let processName = uniquePorts.first?.processName ?? "Unknown"
            
            // Find all PIDs that share the same process name and ports
            var relatedPIDs: Set<Int> = [pid]
            if let portMap = processPortMap[processName] {
                // Collect all PIDs that share at least one port with this process
                for port in uniquePorts {
                    if let pidsForPort = portMap[port.port] {
                        relatedPIDs.formUnion(pidsForPort)
                    }
                }
            }
            
            return ProcessGroup(
                id: pid,
                processName: processName,
                ports: uniquePorts.sorted { $0.port < $1.port },
                relatedPIDs: relatedPIDs
            )
        }.sorted { a, b in
            // Check if groups have favorite or watched ports
            let aHasFavorite = a.ports.contains(where: { state.isFavorite($0.port) })
            let aHasWatched = a.ports.contains(where: { state.isWatching($0.port) })
            let bHasFavorite = b.ports.contains(where: { state.isFavorite($0.port) })
            let bHasWatched = b.ports.contains(where: { state.isWatching($0.port) })

            // Priority: Favorite > Watched > Neither
            let aPriority = aHasFavorite ? 2 : (aHasWatched ? 1 : 0)
            let bPriority = bHasFavorite ? 2 : (bHasWatched ? 1 : 0)

            if aPriority != bPriority {
                return aPriority > bPriority
            } else {
                // Same priority, sort alphabetically by process name, then by PID for stability
                let nameComparison = a.processName.localizedCaseInsensitiveCompare(b.processName)
                if nameComparison == .orderedSame {
                    return a.id < b.id
                }
                return nameComparison == .orderedAscending
            }
        }
    }

    /// Filters ports based on search text and sorts by favorites
    private var filteredPorts: [PortInfo] {
        let filtered = searchText.isEmpty ? state.ports : state.ports.filter {
            String($0.port).contains(searchText) || $0.processName.localizedCaseInsensitiveContains(searchText)
        }
        return filtered.sorted { a, b in
            let aFav = state.isFavorite(a.port)
            let bFav = state.isFavorite(b.port)
            if aFav != bFav { return aFav }
            return a.port < b.port
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeader(searchText: $searchText, portCount: filteredPorts.count)

            Divider()

            MenuBarPortList(
                filteredPorts: filteredPorts,
                groupedByProcess: groupedByProcess,
                useTreeView: useTreeView,
                expandedProcesses: $expandedProcesses,
                confirmingKillPort: $confirmingKillPort,
                state: state
            )

            Divider()

            MenuBarActions(
                confirmingKillAll: $confirmingKillAll,
                useTreeView: $useTreeView,
                state: state,
                openWindow: openWindow
            )
        }
        .frame(width: 340)
        .onAppear { updateGroupedByProcess() }
        .onChange(of: state.ports) { _, _ in updateGroupedByProcess() }
        .onChange(of: searchText) { _, _ in updateGroupedByProcess() }
    }
}
