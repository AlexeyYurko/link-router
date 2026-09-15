import Foundation

public struct Resolution {
    public let target: BrowserTarget
    public let ruleName: String?

    public init(target: BrowserTarget, ruleName: String?) {
        self.target = target
        self.ruleName = ruleName
    }
}

public enum MatchEngine {
    public static func resolve(
        url: URL,
        sourceBundleID: String?,
        cwd: String? = nil,
        config: Config
    ) -> Resolution {
        for rule in config.rules {
            guard matches(rule: rule, url: url, sourceBundleID: sourceBundleID, cwd: cwd) else { continue }
            return Resolution(target: rule.target, ruleName: rule.name)
        }
        return Resolution(target: config.fallback, ruleName: nil)
    }

    static func matches(rule: Rule, url: URL, sourceBundleID: String?, cwd: String?) -> Bool {
        if let sources = rule.source {
            guard let sourceBundleID = sourceBundleID, sources.contains(sourceBundleID) else { return false }
        }
        guard let match = rule.match, !match.isEmpty else { return true }
        if let pattern = match.host, !host(pattern: pattern, matches: url.host) { return false }
        if let prefix = match.prefix, !url.absoluteString.lowercased().hasPrefix(prefix.lowercased()) { return false }
        if let pattern = match.regex {
            guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                return false
            }
            let range = NSRange(url.absoluteString.startIndex..., in: url.absoluteString)
            guard expression.firstMatch(in: url.absoluteString, options: [], range: range) != nil else {
                return false
            }
        }
        if let pattern = match.cwd, !matches(cwdPattern: pattern, actual: cwd) { return false }
        return true
    }

    static func matches(cwdPattern: String, actual: String?) -> Bool {
        guard let actual = actual else { return false }
        guard cwdPattern != "/" else { return true }
        let normalize: (String) -> String = { $0.hasSuffix("/") && $0.count > 1 ? String($0.dropLast()) : $0 }
        let pattern = normalize(cwdPattern)
        let path = normalize(actual)
        return path == pattern || path.hasPrefix(pattern + "/")
    }

    static func host(pattern: String, matches host: String?) -> Bool {
        guard let hostName = host else { return false }
        var normalized = pattern.lowercased()
        while normalized.hasPrefix("*.") || normalized.hasPrefix("**.") {
            normalized = String(normalized.drop(while: { $0 == "*" || $0 == "." }))
        }
        if normalized.isEmpty { return true }
        return hostName.lowercased().hasSuffix("." + normalized)
            || hostName.lowercased() == normalized
    }
}