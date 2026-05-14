import SwiftUI
import UniformTypeIdentifiers

struct BirdListView: View {
    @ObservedObject var service: EBirdService
    @ObservedObject private var locationStore = LocationStore.shared

    private var todayObservations: [BirdObservation] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return service.observations.filter {
            guard let date = formatter.date(from: $0.obsDt) else { return false }
            return Calendar.current.isDateInToday(date)
        }
    }

    private var earlierObservations: [BirdObservation] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return service.observations.filter {
            guard let date = formatter.date(from: $0.obsDt) else { return false }
            return !Calendar.current.isDateInToday(date)
        }
    }
    
    private var yesterdayObservations: [BirdObservation] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return service.observations.filter {
            guard let date = formatter.date(from: $0.obsDt) else { return false }
            return Calendar.current.isDateInYesterday(date)
        }
    }

    private var olderObservations: [BirdObservation] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return service.observations.filter {
            guard let date = formatter.date(from: $0.obsDt) else { return false }
            return !Calendar.current.isDateInToday(date) && !Calendar.current.isDateInYesterday(date)
        }
    }
    
    private var lastFetchedText: String {
        guard let lastFetched = service.lastFetched else { return "" }
        let minutes = Int(Date().timeIntervalSince(lastFetched) / 60)
        if minutes < 1 { return "Updated just now" }
        return "Updated \(minutes) min ago"
    }
    
    private var totalSpeciesCount: Int {
        Set(service.observations.map { $0.speciesCode }).count
    }

    private var estimatedHeight: CGFloat {
        let headerHeight: CGFloat = 70
        let footerHeight: CGFloat = 35
        let rowHeight: CGFloat = 34
        let sectionLabelHeight: CGFloat = 30
        let dividerHeight: CGFloat = 2

        var height = headerHeight + footerHeight + dividerHeight
        height += sectionLabelHeight
        height += CGFloat(todayObservations.count) * rowHeight
        if !yesterdayObservations.isEmpty {
            height += sectionLabelHeight
            height += CGFloat(yesterdayObservations.count) * rowHeight
        }
        if !olderObservations.isEmpty {
            height += sectionLabelHeight
            height += CGFloat(olderObservations.count) * rowHeight
        }
        return height
    }
    
    private func exportObservations() {
        let locationName = locationStore.currentLocation?.name ?? "Unknown Location"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let exportDate = formatter.string(from: Date())

        var lines: [String] = []
        lines.append("\(locationName) — exported \(exportDate)")
        lines.append("\(totalSpeciesCount) species")
        lines.append("")

        if !todayObservations.isEmpty {
            lines.append("TODAY")
            for obs in todayObservations {
                var line = "\(formattedDate(obs.obsDt))  \(obs.comName)"
                if let count = obs.howMany { line += "  \(count)" }
                lines.append(line)
            }
            lines.append("")
        }

        if !yesterdayObservations.isEmpty {
            lines.append("YESTERDAY")
            for obs in yesterdayObservations {
                var line = "\(formattedDate(obs.obsDt))  \(obs.comName)"
                if let count = obs.howMany { line += "  \(count)" }
                lines.append(line)
            }
            lines.append("")
        }

        if !olderObservations.isEmpty {
            lines.append("EARLIER")
            for obs in olderObservations {
                var line = "\(formattedDate(obs.obsDt))  \(obs.comName)"
                if let count = obs.howMany { line += "  \(count)" }
                lines.append(line)
            }
        }

        let content = lines.joined(separator: "\n")

        let fileFormatter = DateFormatter()
        fileFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let fileDate = fileFormatter.string(from: Date())
        let safeName = locationName.replacingOccurrences(of: "/", with: "-")
        let filename = "\(safeName)_\(fileDate).txt"

        AppDelegate.shared?.popover?.performClose(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = filename
            savePanel.allowedContentTypes = [.plainText]
            savePanel.begin { result in
                if result == .OK, let url = savePanel.url {
                    try? content.write(to: url, atomically: true, encoding: .utf8)
                }
            }
        }
    }
    
    @State private var showCounts: Bool = UserDefaults.standard.bool(forKey: "showCounts")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(locationStore.currentLocation?.name ?? "Select a location")
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        
                        Menu {
                            ForEach(locationStore.locations) { location in
                                Button {
                                    locationStore.currentLocationID = location.id
                                    locationStore.saveLastUsed()
                                    service.fetchRecentObservations()
                                } label: {
                                    HStack {
                                        Text(location.name)
                                        if location.id == locationStore.defaultLocationID {
                                            Image(systemName: "star.fill")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .menuIndicator(.hidden)
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .labelStyle(.iconOnly)
                    }
                    
                    Text(lastFetchedText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(totalSpeciesCount) species in the last two weeks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                
                if let locationID = locationStore.currentLocationID,
                   let url = URL(string: "https://ebird.org/hotspot/\(locationID)") {
                    Link(destination: url) {
                        Image(systemName: "link")
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    service.fetchRecentObservations(forceRefresh: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)

                Button {
                    exportObservations()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                
            }
            .padding()

            Divider()

            // Content
            if service.isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if let error = service.errorMessage {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            } else if service.observations.isEmpty {
                Spacer()
                Text("No observations found.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    Section(header: Text("\(todayObservations.count) TODAY")
                        .font(.subheadline)
                        .foregroundColor(.secondary)) {
                        ForEach(todayObservations) { obs in
                            HStack {
                                Text(obs.comName)
                                    .font(.body)
                                if showCounts, let count = obs.howMany {
                                    Text("\(count)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(formattedDate(obs.obsDt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    if !yesterdayObservations.isEmpty {
                        Text("\(yesterdayObservations.count) YESTERDAY")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .listRowSeparator(.hidden)
                            .padding(.top, 8)
                        ForEach(yesterdayObservations) { obs in
                            HStack {
                                Text(obs.comName)
                                    .font(.body)
                                if showCounts, let count = obs.howMany {
                                    Text("\(count)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(formattedDate(obs.obsDt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    if !olderObservations.isEmpty {
                        Text("\(olderObservations.count) EARLIER")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .listRowSeparator(.hidden)
                            .padding(.top, 8)
                        ForEach(olderObservations) { obs in
                            HStack {
                                Text(obs.comName)
                                    .font(.body)
                                if showCounts, let count = obs.howMany {
                                    Text("\(count)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(formattedDate(obs.obsDt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            // Footer
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .font(.caption)
            .padding(8)
        }
        .onChange(of: service.observations.count) { _ in
            NotificationCenter.default.post(name: .contentHeightChanged, object: nil, userInfo: ["height": estimatedHeight])
        }
        .onReceive(NotificationCenter.default.publisher(for: .settingsSaved)) { _ in
            showCounts = UserDefaults.standard.bool(forKey: "showCounts")
            service.fetchRecentObservations()
        }
    }

    private func openSettings() {
        AppDelegate.shared?.popover?.performClose(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SettingsWindowManager.shared.open()
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "MM-dd"
        }
        return formatter.string(from: date)
    }
}

class SettingsWindowManager: NSObject {
    static let shared = SettingsWindowManager()
    var window: NSWindow?

    func open() {
        if window == nil {
            let settingsView = SettingsView()
            let controller = NSHostingController(rootView: settingsView)
            let win = NSWindow(contentViewController: controller)
            win.title = "Settings"
            win.styleMask = [.titled, .closable]
            win.setContentSize(NSSize(width: 500, height: controller.view.fittingSize.height))
            win.delegate = self
            win.level = .normal
            win.setFrameTopLeftPoint(NSPoint(x: 0, y: NSScreen.main!.frame.height - 20))
            window = win
        }
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension SettingsWindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        window = nil
        NotificationCenter.default.post(name: .settingsDidClose, object: nil)
    }
}

extension Notification.Name {
    static let settingsDidClose = Notification.Name("settingsDidClose")
    static let settingsSaved = Notification.Name("settingsSaved")
    static let contentHeightChanged = Notification.Name("contentHeightChanged")
}
