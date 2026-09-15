import Foundation
import RouterCore

private func temporaryFile(contents: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("router-tests-\(UUID().uuidString)")
    try contents.write(to: url, atomically: true, encoding: .utf8)
    return url
}

func runProfileDiscoveryTests() {
    do {
        let localState = """
        {
          "profile": {
            "info_cache": {
              "Default": { "name": "Colophon" },
              "Profile 1": { "name": "Work" }
            }
          }
        }
        """
        let url = try temporaryFile(contents: localState)
        defer { try? FileManager.default.removeItem(at: url) }
        let names = ProfileDiscovery.chromiumProfileNames(bundleID: "com.google.Chrome", localStateURL: url)
        checkEqual(names["work"], "Profile 1", "chrome profile friendly name")
        checkEqual(names["colophon"], "Default", "chrome default profile")
        checkEqual(
            ProfileDiscovery.resolveChromiumProfile("Work", bundleID: "com.google.Chrome", localStateURL: url),
            "Profile 1", "resolve friendly name")
        checkEqual(
            ProfileDiscovery.resolveChromiumProfile("work", bundleID: "com.google.Chrome", localStateURL: url),
            "Profile 1", "resolve case-insensitive name")
        checkEqual(
            ProfileDiscovery.resolveChromiumProfile("Profile 3", bundleID: "com.google.Chrome", localStateURL: url),
            "Profile 3", "directory name passthrough")
        checkEqual(
            ProfileDiscovery.resolveChromiumProfile("Default", bundleID: "com.google.Chrome", localStateURL: url),
            "Default", "default directory passthrough")
        checkNil(ProfileDiscovery.resolveChromiumProfile("Missing", bundleID: "com.google.Chrome", localStateURL: url),
                 "unknown profile")
    } catch {
        check(false, "chromium test failed: \(error)")
    }

    do {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: missing) }
        check(ProfileDiscovery.chromiumProfileNames(bundleID: "com.google.Chrome", localStateURL: missing).isEmpty,
              "missing local state yields empty names")
    }
}

func runBrowserLauncherTests() {
    let url = URL(string: "https://example.com")!

    let chrome = BrowserLauncher.openCommand(
        url: url,
        target: BrowserTarget(browser: "com.google.Chrome")
    )
    checkEqual(chrome, ["/usr/bin/open", "-n", "-b", "com.google.Chrome", "--args", "https://example.com"],
               "chrome without profile")

    let firefoxProfile = BrowserLauncher.openCommand(
        url: url,
        target: BrowserTarget(browser: "org.mozilla.firefox", profile: "Work")
    )
    checkEqual(firefoxProfile,
               ["/usr/bin/open", "-b", "org.mozilla.firefox", "--args", "-no-remote", "-P", "Work", "https://example.com"],
               "firefox with profile")

    let firefoxPlain = BrowserLauncher.openCommand(
        url: url,
        target: BrowserTarget(browser: "org.mozilla.firefox")
    )
    checkEqual(firefoxPlain, ["/usr/bin/open", "-b", "org.mozilla.firefox", "https://example.com"], "firefox plain")

    let safari = BrowserLauncher.openCommand(
        url: url,
        target: BrowserTarget(browser: "com.apple.Safari")
    )
    checkEqual(safari, ["/usr/bin/open", "-b", "com.apple.Safari", "https://example.com"], "safari plain")

    let chromeWithArgs = BrowserLauncher.openCommand(
        url: url,
        target: BrowserTarget(browser: "com.google.Chrome", args: ["--incognito"])
    )
    checkEqual(chromeWithArgs, ["/usr/bin/open", "-n", "-b", "com.google.Chrome", "--args", "https://example.com", "--incognito"],
               "chrome extra args")
}