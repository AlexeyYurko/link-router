import Foundation
import RouterCore

func runNameAndConfigTests() {
    // BrowserName display/reverse
    checkEqual(BrowserName.displayName(for: "com.google.Chrome"), "Chrome")
    checkEqual(BrowserName.displayName(for: "org.mozilla.firefox"), "Firefox")
    checkEqual(BrowserName.displayName(for: "com.apple.Safari"), "Safari")
    checkEqual(BrowserName.displayName(for: "com.unknown.App"), "com.unknown.App", "unknown bundle IDs pass through")
    checkEqual(BrowserName.bundleID(for: "chrome"), "com.google.Chrome", "case-insensitive lookup")
    checkEqual(BrowserName.bundleID(for: "Firefox"), "org.mozilla.firefox")
    checkEqual(BrowserName.bundleID(for: "safari"), "com.apple.Safari")
    checkNil(BrowserName.bundleID(for: "Lynx"), "unknown name -> nil")
    checkNil(BrowserName.bundleID(for: "com.google.Chrome"), "bundle IDs are not reversed")

    // Config.normalize resolves friendly names to bundle IDs
    let rawConfig = """
    {"fallback":{"browser":"Chrome"},"rules":[{"name":"R","match":{"host":"h"},"target":{"browser":"Safari"}}]}
    """
    let decoded = try? JSONDecoder().decode(Config.self, from: Data(rawConfig.utf8))
    check(decoded != nil, "test config decodes")
    let normalized = ConfigLoader.normalize(decoded!)
    checkEqual(normalized.fallback.browser, "com.google.Chrome")
    checkEqual(normalized.rules.first?.target.browser, "com.apple.Safari")

    // Log.redacted strips query strings and fragments
    checkEqual(Log.redacted("https://example.com/reset?token=secret"), "https://example.com/reset…", "query stripped")
    checkEqual(Log.redacted("https://example.com/page#section"), "https://example.com/page…", "fragment stripped")
    checkEqual(Log.redacted("https://example.com/a?x=1#frag"), "https://example.com/a…", "earliest marker wins")
    checkEqual(Log.redacted("https://example.com/path"), "https://example.com/path", "no query unchanged")
}
