import SwiftUI

@main
struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    let service = EBirdService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(named: "BirdIcon") {
                image.isTemplate = true
                button.image = image
            }
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 480)
        
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(rootView: BirdListView(service: service))
        self.popover = popover

        NotificationCenter.default.addObserver(forName: NSPopover.willShowNotification, object: popover, queue: .main) { _ in
            self.service.fetchRecentObservations()
        }
        NotificationCenter.default.addObserver(forName: .contentHeightChanged, object: nil, queue: .main) { notification in
            if let height = notification.userInfo?["height"] as? CGFloat {
                if let screenHeight = NSScreen.main?.visibleFrame.height {
                    let maxHeight = screenHeight - 50
                    self.popover?.contentSize = NSSize(width: 320, height: min(height, maxHeight))
                }
            }
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                if let screenHeight = NSScreen.main?.visibleFrame.height {
                    let maxHeight = screenHeight - 50
                    popover.contentSize = NSSize(width: 320, height: min(CGFloat(maxHeight), 800))
                }
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    func applicationDidResignActive(_ notification: Notification) {
        popover?.performClose(nil)
    }
}
