import SwiftUI

struct PortDetailView: View {
    let port: PortInfo
    @Environment(AppState.self) private var appState
    @State private var showKillConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                header

                Divider()

                // Details Grid
                detailsGrid

                Divider()

                // Command
                commandSection

                Divider()

                // Actions
                actionsSection
            }
            .padding()
        }
        .frame(minWidth: 300)
        .confirmationDialog(
            "Kill Process",
            isPresented: $showKillConfirmation
        ) {
            Button("Kill Process", role: .destructive) {
                Task {
                    await appState.killPort(port)
                }
            }
            Button("Force Kill (SIGKILL)", role: .destructive) {
                Task {
                    await appState.killPort(port)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to kill \(port.processName) on port \(String(port.port))?")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: port.processType.icon)
                    .font(.title2)
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(port.processName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if appState.isFavorite(port.port) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }

                    if appState.isWatching(port.port) {
                        Image(systemName: "eye.fill")
                            .foregroundStyle(.blue)
                    }
                }

                Text("Port \(String(port.port))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(port.processType.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(typeColor.opacity(0.2))
                .foregroundStyle(typeColor)
                .clipShape(Capsule())
        }
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], alignment: .leading, spacing: 16) {
            DetailRow(title: "Port", value: String(port.port))
            DetailRow(title: "PID", value: String(port.pid))
            DetailRow(title: "Address", value: port.address)
            DetailRow(title: "User", value: port.user)
            DetailRow(title: "File Descriptor", value: port.fd)
            DetailRow(title: "Type", value: port.processType.rawValue)
        }
    }

    private var commandSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Command")
                    .font(.headline)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(port.command, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text(port.command)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            HStack(spacing: 12) {
                Button {
                    appState.toggleFavorite(port.port)
                } label: {
                    Label(
                        appState.isFavorite(port.port) ? "Remove Favorite" : "Add Favorite",
                        systemImage: appState.isFavorite(port.port) ? "star.slash" : "star"
                    )
                }
                .buttonStyle(.bordered)

                Button {
                    appState.toggleWatch(port.port)
                } label: {
                    Label(
                        appState.isWatching(port.port) ? "Stop Watching" : "Watch",
                        systemImage: appState.isWatching(port.port) ? "eye.slash" : "eye"
                    )
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(role: .destructive) {
                    showKillConfirmation = true
                } label: {
                    Label("Kill Process", systemImage: "xmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
    }

    private var typeColor: Color {
        switch port.processType {
        case .webServer: return .blue
        case .database: return .purple
        case .development: return .orange
        case .system: return .gray
        case .other: return .secondary
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}
