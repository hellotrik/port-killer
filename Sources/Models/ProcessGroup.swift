/**
 * ProcessGroup.swift
 * PortKiller
 *
 * Groups multiple ports owned by the same process together.
 * Used in tree view mode to display processes and their ports hierarchically.
 */

import Foundation

/// A collection of ports owned by the same process
///
/// ProcessGroup is used in tree view mode to organize multiple ports under
/// their owning process. This provides a hierarchical view where users can
/// expand/collapse processes to see all their associated ports.
struct ProcessGroup: Identifiable, Sendable {
    /// Process ID (PID) - used as stable identifier
    let id: Int

    /// Name of the process owning these ports
    let processName: String

    /// All ports owned by this process
    let ports: [PortInfo]
    
    /// All PIDs that share the same process name and ports (for multi-process scenarios like nginx workers)
    /// This helps identify when multiple processes are listening on the same ports
    let relatedPIDs: Set<Int>
    
    /// Whether this process shares ports with other processes of the same name
    var hasRelatedProcesses: Bool {
        relatedPIDs.count > 1
    }
}
