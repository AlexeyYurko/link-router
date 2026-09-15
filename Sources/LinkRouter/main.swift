import AppKit
import CoreServices
import Darwin
import Foundation
import RouterCore

let bundleID = Bundle.main.bundleIdentifier ?? "dev.ayurko.LinkRouter"

SourceAppDetector.captureFrontmostAtLaunch()

if CommandLine.arguments.count > 1, CommandLine.arguments[1] == "--set-default" {
    LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID as CFString)
    LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID as CFString)
    print("set \(bundleID) as default handler for http/https")
    exit(0)
}

if CommandLine.arguments.count > 1, CommandLine.arguments[1] == "--route" {
    var urlString: String?
    var source: String?
    var cwd: String? = FileManager.default.currentDirectoryPath
    var dryRun = false
    var index = 2
    while index < CommandLine.arguments.count {
        let arg = CommandLine.arguments[index]
        if arg == "--source" {
            index += 1
            if index < CommandLine.arguments.count { source = CommandLine.arguments[index] }
        } else if arg == "--cwd" {
            index += 1
            if index < CommandLine.arguments.count { cwd = CommandLine.arguments[index] }
        } else if arg == "--dry-run" {
            dryRun = true
        } else {
            urlString = arg
        }
        index += 1
    }
    guard let urlString = urlString, let url = URL(string: urlString), url.scheme != nil else {
        fputs("usage: LinkRouter --route <url> [--source <bundle-id>] [--cwd <dir>] [--dry-run]\n", stderr)
        exit(2)
    }
    let config = Router.load()
    let resolution = Router.route(url: url, source: source, cwd: cwd, config: config)
    if dryRun {
        let profile = resolution.target.profile.map { " (\($0))" } ?? ""
        print("\(resolution.target.browser)\(profile) url=\(url.absoluteString)")
    } else {
        BrowserLauncher.open(url: url, target: resolution.target)
    }
    exit(0)
}

if CommandLine.arguments.count > 1, CommandLine.arguments[1] == "--quit" {
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    if let instance = running.first {
        DistributedNotificationCenter.default().postNotificationName(
            AppDelegate.quitNotificationName,
            object: nil,
            deliverImmediately: true
        )
        print("asked LinkRouter (pid \(instance.processIdentifier)) to quit")
    } else {
        print("LinkRouter is not running")
    }
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()