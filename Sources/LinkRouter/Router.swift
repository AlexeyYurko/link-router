import Foundation
import RouterCore

enum Router {
    static func load() -> Config {
        ConfigLoader.loadOrCreate { Log.write($0) }
    }

    static func route(url: URL, source: String?, cwd: String?, config: Config) -> Resolution {
        let resolution = MatchEngine.resolve(url: url, sourceBundleID: source, cwd: cwd, config: config)
        log(resolution: resolution, url: url, source: source, cwd: cwd)
        return resolution
    }

    static func handle(urlString: String?, source: String?) {
        guard let urlString = urlString, !urlString.isEmpty, let url = URL(string: urlString) else {
            Log.write("ignoring invalid URL: \(Log.redacted(urlString ?? "<nil>")) source=\(source ?? "unknown")")
            return
        }
        let resolution = route(url: url, source: source, cwd: nil, config: load())
        BrowserLauncher.open(url: url, target: resolution.target)
    }

    static func log(resolution: Resolution, url: URL, source: String?, cwd: String?) {
        let profile = resolution.target.profile ?? "-"
        let cwdSuffix = cwd.map { " cwd=\($0)" } ?? ""
        let redacted = Log.redacted(url.absoluteString)
        if let ruleName = resolution.ruleName {
            Log.write("match rule '\(ruleName)' -> \(resolution.target.browser) profile=\(profile) url=\(redacted) source=\(source ?? "unknown")\(cwdSuffix)")
        } else {
            Log.write("no rule -> fallback \(resolution.target.browser) profile=\(profile) url=\(redacted) source=\(source ?? "unknown")\(cwdSuffix)")
        }
    }
}