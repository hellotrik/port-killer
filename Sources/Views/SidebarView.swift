import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        List(selection: $state.selectedSidebarItem) {
            Section("Categories") {
                sidebarRow(.allPorts, count: appState.ports.count)
                sidebarRow(.favorites, count: favoritesCount)
                sidebarRow(.watched, count: watchedCount)
            }

            Section("Process Types") {
                ForEach(ProcessType.allCases) { type in
                    sidebarRow(.processType(type), count: countForType(type))
                }
            }

            Section("Filters") {
                filterControls
            }

            Section {
                Label("Settings", systemImage: "gear")
                    .tag(SidebarItem.settings)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }

    private func sidebarRow(_ item: SidebarItem, count: Int) -> some View {
        Label {
            HStack {
                Text(item.title)
                Spacer()
                Text("\(count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        } icon: {
            Image(systemName: item.icon)
        }
        .tag(item)
    }

    @ViewBuilder
    private var filterControls: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 12) {
            // Port range
            VStack(alignment: .leading, spacing: 4) {
                Text("Port Range")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Min", value: $state.filter.minPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("-")
                        .foregroundStyle(.secondary)
                    TextField("Max", value: $state.filter.maxPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }

            // Reset button
            if appState.filter.isActive {
                Button("Reset Filters") {
                    appState.filter.reset()
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var favoritesCount: Int {
        appState.ports.filter { appState.favorites.contains($0.port) }.count
    }

    private var watchedCount: Int {
        let watchedPortNumbers = Set(appState.watchedPorts.map { $0.port })
        return appState.ports.filter { watchedPortNumbers.contains($0.port) }.count
    }

    private func countForType(_ type: ProcessType) -> Int {
        appState.ports.filter { $0.processType == type }.count
    }
}
