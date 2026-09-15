import AppKit
import RouterCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let quitNotificationName = Notification.Name("dev.ayurko.LinkRouter.quit")
    private let internetEventClass = AEEventClass(0x4755524C)
    private let getURL = AEEventID(0x4755524C)

    func applicationWillFinishLaunching(_ notification: Notification) {
        SourceAppDetector.startTrackingActiveApps()
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: internetEventClass,
            andEventID: getURL
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(quit),
            name: Self.quitNotificationName,
            object: nil
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.write("LinkRouter ready (pid \(ProcessInfo.processInfo.processIdentifier))")
    }

    func applicationWillTerminate(_ notification: Notification) {
        Log.write("LinkRouter stopped")
    }

    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue
        let source = SourceAppDetector.detect(from: event)
        Router.handle(urlString: urlString, source: source)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
