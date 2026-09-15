import AppKit
import RouterCore

enum SourceAppDetector {
    private static let senderAddressKeyword = AEKeyword(0x61646472)
    private static let applicationBundleIDType = DescType(0x70626964)
    private static let kernelProcessIDType = DescType(0x70696420)
    private static let linkRouterBundleID = "dev.ayurko.LinkRouter"

    private static var frontmostAtLaunch: String?
    private static var lastActiveApp: String?
    private static var activationObserver: NSObjectProtocol?

    static func captureFrontmostAtLaunch() {
        frontmostAtLaunch = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    static func startTrackingActiveApps() {
        guard activationObserver == nil else { return }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier,
                  bundleID != linkRouterBundleID else { return }
            lastActiveApp = bundleID
        }
    }

    static func detect(from event: NSAppleEventDescriptor) -> String? {
        if let sender = event.attributeDescriptor(forKeyword: senderAddressKeyword) {
            if let descriptor = sender.coerce(toDescriptorType: applicationBundleIDType),
               let bundleID = descriptor.stringValue, !bundleID.isEmpty,
               bundleID != linkRouterBundleID {
                return bundleID
            }
            if let descriptor = sender.coerce(toDescriptorType: kernelProcessIDType) {
                let data = descriptor.data
                if data.count == MemoryLayout<pid_t>.size {
                    let pid = data.withUnsafeBytes { $0.load(as: pid_t.self) }
                    if let app = NSRunningApplication(processIdentifier: pid),
                       let bundleID = app.bundleIdentifier,
                       bundleID != linkRouterBundleID {
                        return bundleID
                    }
                }
            }
        }
        if let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           frontmost != linkRouterBundleID {
            return frontmost
        }
        if let lastActiveApp {
            return lastActiveApp
        }
        if let frontmostAtLaunch, frontmostAtLaunch != linkRouterBundleID {
            return frontmostAtLaunch
        }
        let sender = event.attributeDescriptor(forKeyword: senderAddressKeyword)
            .map { "type=\($0.descriptorType)" } ?? "none"
        Log.write("source unknown: sender \(sender), frontmost=\(NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "nil"), lastActive=\(lastActiveApp ?? "nil")")
        return nil
    }
}
