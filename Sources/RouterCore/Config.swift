import Foundation

public struct BrowserTarget: Codable, Equatable {
    public var browser: String
    public var profile: String?
    public var args: [String]?

    public init(browser: String, profile: String? = nil, args: [String]? = nil) {
        self.browser = browser
        self.profile = profile
        self.args = args
    }
}

public struct URLMatch: Codable, Equatable {
    public var host: String?
    public var prefix: String?
    public var regex: String?
    public var cwd: String?

    public init(host: String? = nil, prefix: String? = nil, regex: String? = nil, cwd: String? = nil) {
        self.host = host
        self.prefix = prefix
        self.regex = regex
        self.cwd = cwd
    }

    public var isEmpty: Bool {
        host == nil && prefix == nil && regex == nil && cwd == nil
    }
}

public struct Rule: Codable, Equatable {
    public var name: String
    public var source: [String]?
    public var match: URLMatch?
    public var target: BrowserTarget

    public init(name: String, source: [String]? = nil, match: URLMatch? = nil, target: BrowserTarget) {
        self.name = name
        self.source = source
        self.match = match
        self.target = target
    }
}

public struct Config: Codable, Equatable {
    public var fallback: BrowserTarget
    public var rules: [Rule]

    public init(fallback: BrowserTarget, rules: [Rule]) {
        self.fallback = fallback
        self.rules = rules
    }
}

public enum ConfigLoader {
    public static func location() -> URL {
        if let env = ProcessInfo.processInfo.environment["LINK_ROUTER_CONFIG"] {
            return URL(fileURLWithPath: env)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/link-router/config.json")
    }

    public static func loadOrCreate(_ log: (String) -> Void = { _ in }) -> Config {
        let fileManager = FileManager.default
        let url = location()
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                let seed = Config(
                    fallback: BrowserTarget(browser: "com.apple.Safari"),
                    rules: [
                        Rule(name: "GitHub in Chrome", match: URLMatch(host: "github.com"),
                             target: BrowserTarget(browser: "com.google.Chrome")),
                        Rule(name: "Slack links in Chrome", source: ["com.tinyspeck.slackmacgap"],
                             target: BrowserTarget(browser: "com.google.Chrome")),
                    ]
                )
                let data = try seedEncoder().encode(seed)
                try data.write(to: url, options: .atomic)
                log("seeded config at \(url.path)")
            } catch {
                log("could not write seed config: \(error)")
            }
        }
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(Config.self, from: data)
            log("loaded \(config.rules.count) rule(s) from \(url.path)")
            return Self.normalize(config)
        } catch {
            log("config load failed (\(error.localizedDescription)); using empty config")
            return Config(fallback: BrowserTarget(browser: "com.apple.Safari"), rules: [])
        }
    }

    public static func normalize(_ config: Config) -> Config {
        func resolved(_ target: BrowserTarget) -> BrowserTarget {
            guard let bundleID = BrowserName.bundleID(for: target.browser) else { return target }
            return BrowserTarget(browser: bundleID, profile: target.profile, args: target.args)
        }
        return Config(
            fallback: resolved(config.fallback),
            rules: config.rules.map { Rule(name: $0.name, source: $0.source, match: $0.match, target: resolved($0.target)) }
        )
    }

    static func seedEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}