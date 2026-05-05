import SwiftUI

struct BirdListView: View {
    @ObservedObject var service: EBirdService
    
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
    
    private var totalSpeciesCount: Int {
        Set(service.observations.map { $0.speciesCode }).count
    }
    
    @State private var showCounts: Bool = UserDefaults.standard.bool(forKey: "showCounts")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.observations.first?.locName ?? (service.errorMessage != nil ? "Invalid Location ID" : "Location ID"))
                        .font(.title3)
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

                Button {
                    service.fetchRecentObservations()
                } label: {
                    Image(systemName: "arrow.clockwise")
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
        .frame(width: 320, height: 480)
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
            win.setContentSize(controller.view.fittingSize)
            win.delegate = self
            win.level = .normal
            win.setFrameTopLeftPoint(NSPoint(x: 0, y: NSScreen.main!.frame.height - 20))
            window = win
        }
        window?.makeKeyAndOrderFront(nil)
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
}
