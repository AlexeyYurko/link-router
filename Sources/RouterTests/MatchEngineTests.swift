import Foundation
import RouterCore

func runMatchEngineTests() {
    func config(rules: [Rule]) -> Config {
        Config(fallback: BrowserTarget(browser: "com.apple.Safari"), rules: rules)
    }

    func resolve(_ urlString: String, rules: [Rule], source: String? = nil, cwd: String? = nil) -> Resolution {
        MatchEngine.resolve(url: URL(string: urlString)!, sourceBundleID: source, cwd: cwd, config: config(rules: rules))
    }

    do {
        let rules = [
            Rule(name: "gh", match: URLMatch(host: "github.com"),
                 target: BrowserTarget(browser: "com.google.Chrome"))
        ]
        checkEqual(resolve("https://github.com/x", rules: rules).target.browser, "com.google.Chrome", "apex host")
        checkEqual(resolve("https://api.github.com/x", rules: rules).target.browser, "com.google.Chrome", "subdomain host")
        checkNil(resolve("https://evilgithub.com/x", rules: rules).ruleName, "suffix collision")
        checkNil(resolve("https://github.com.evil.example/x", rules: rules).ruleName, "embedded host")
    }

    do {
        let rules = [
            Rule(name: "wc", match: URLMatch(host: "*.atlassian.net"),
                 target: BrowserTarget(browser: "com.google.Chrome"))
        ]
        checkEqual(resolve("https://atlassian.net/", rules: rules).target.browser, "com.google.Chrome", "wildcard apex")
        checkEqual(resolve("https://mycorp.atlassian.net/browse/X", rules: rules).target.browser, "com.google.Chrome", "wildcard subdomain")
        checkNil(resolve("https://notatlassian.net/", rules: rules).ruleName, "wildcard collision")
    }

    do {
        let rules = [
            Rule(name: "prefix", match: URLMatch(prefix: "https://example.com/app"),
                 target: BrowserTarget(browser: "com.google.Chrome"))
        ]
        checkEqual(resolve("HTTPS://EXAMPLE.COM/APP/ROUTE?q=1", rules: rules).target.browser, "com.google.Chrome", "case-insensitive prefix")
        checkNil(resolve("https://example.com/other", rules: rules).ruleName, "prefix mismatch")
    }

    do {
        let rules = [
            Rule(name: "zoom", match: URLMatch(regex: "zoom\\.us/(j|w)/"),
                 target: BrowserTarget(browser: "us.zoom.xos"))
        ]
        checkEqual(resolve("https://us06web.zoom.us/j/123", rules: rules).target.browser, "us.zoom.xos", "regex match")
        checkNil(resolve("https://zoom.us/pricing", rules: rules).ruleName, "regex mismatch")
    }

    do {
        let rules = [
            Rule(name: "combo", match: URLMatch(host: "example.com", regex: "^https://example\\.com/app"),
                 target: BrowserTarget(browser: "com.google.Chrome"))
        ]
        checkEqual(resolve("https://example.com/app/x", rules: rules).target.browser,
                   "com.google.Chrome", "host and regex must both match")
        checkNil(resolve("https://example.com/other", rules: rules).ruleName, "regex narrows host match")
    }

    do {
        let rules = [
            Rule(name: "bad-regex", match: URLMatch(host: "example.com", regex: "[unclosed"),
                 target: BrowserTarget(browser: "com.google.Chrome"))
        ]
        checkNil(resolve("https://example.com/x", rules: rules).ruleName, "invalid regex fails closed")
    }

    do {
        let rules = [
            Rule(name: "slack", source: ["com.tinyspeck.slackmacgap"],
                 target: BrowserTarget(browser: "com.google.Chrome", profile: "Work"))
        ]
        let matched = resolve("https://example.com", rules: rules, source: "com.tinyspeck.slackmacgap")
        checkEqual(matched.target.browser, "com.google.Chrome", "source match")
        checkEqual(matched.target.profile, "Work", "source match profile")
        let unmatched = resolve("https://example.com", rules: rules, source: "com.apple.Terminal")
        checkNil(unmatched.ruleName, "source mismatch falls through")
        checkEqual(unmatched.target.browser, "com.apple.Safari", "source mismatch fallback")
        checkNil(resolve("https://example.com", rules: rules).ruleName, "nil source")
    }

    do {
        let rules = [
            Rule(name: "first", match: URLMatch(host: "example.com"), target: BrowserTarget(browser: "com.google.Chrome")),
            Rule(name: "second", match: URLMatch(host: "example.com"), target: BrowserTarget(browser: "com.apple.Safari")),
        ]
        let resolution = resolve("https://example.com", rules: rules)
        checkEqual(resolution.ruleName, "first", "first match wins")
        checkEqual(resolution.target.browser, "com.google.Chrome", "first match target")
    }

    do {
        let rules = [
            Rule(name: "catch-all-by-source", source: ["com.apple.Terminal"],
                 target: BrowserTarget(browser: "com.google.Chrome"))
        ]
        checkEqual(resolve("https://anything.example/x?y=z", rules: rules, source: "com.apple.Terminal").target.browser,
                   "com.google.Chrome", "rule without URL match")
    }

    do {
        let rules = [
            Rule(name: "cwd", match: URLMatch(cwd: "/Users/me/projects"),
                 target: BrowserTarget(browser: "com.google.Chrome"))
        ]
        checkEqual(resolve("https://example.com", rules: rules, cwd: "/Users/me/projects").target.browser,
                   "com.google.Chrome", "exact cwd")
        checkEqual(resolve("https://example.com", rules: rules, cwd: "/Users/me/projects/app").target.browser,
                   "com.google.Chrome", "child dir of cwd")
        checkEqual(resolve("https://example.com", rules: rules, cwd: "/Users/me/projects/").target.browser,
                   "com.google.Chrome", "trailing slash tolerated")
        checkNil(resolve("https://example.com", rules: rules, cwd: "/Users/me/other").ruleName, "sibling dir mismatch")
        checkNil(resolve("https://example.com", rules: rules, cwd: "/Users/me/project").ruleName, "prefix must end at component")
        checkNil(resolve("https://example.com", rules: rules).ruleName, "nil cwd never matches")
    }

    do {
        let rules = [
            Rule(name: "cwd-root", match: URLMatch(cwd: "/"),
                 target: BrowserTarget(browser: "com.google.Chrome"))
        ]
        checkEqual(resolve("https://example.com", rules: rules, cwd: "/Users/me/projects").target.browser,
                   "com.google.Chrome", "root cwd matches everything")
    }

    do {
        let resolution = resolve("https://example.com", rules: [])
        checkNil(resolution.ruleName, "empty rules fallback")
        checkEqual(resolution.target.browser, "com.apple.Safari", "fallback target")
    }
}