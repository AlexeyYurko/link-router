import Foundation

public enum BrowserFamily: Equatable {
    case chromium
    case firefox
    case safari
    case other

    public init(bundleID: String) {
        if bundleID == "com.apple.Safari" {
            self = .safari
        } else if Self.firefoxBundleIDs.contains(bundleID) {
            self = .firefox
        } else if Self.chromiumBundleIDs.contains(bundleID) {
            self = .chromium
        } else {
            self = .other
        }
    }

    static let chromiumBundleIDs: Set<String> = [
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.google.Chrome.beta",
        "com.google.Chrome.dev",
        "com.brave.Browser",
        "com.brave.Browser.beta",
        "com.microsoft.edgemac",
        "com.microsoft.edgemac.beta",
        "com.microsoft.edgemac.canary",
        "com.vivaldi.Vivaldi",
        "com.operasoftware.Opera",
        "ru.yandex.desktop.yandex-browser",
        "org.chromium.Chromium",
    ]

    static let firefoxBundleIDs: Set<String> = [
        "org.mozilla.firefox",
        "org.mozilla.firefoxdeveloperedition",
        "org.mozilla.nightly",
    ]

    static func applicationSupportDirectory(bundleID: String) -> String? {
        switch bundleID {
        case "com.google.Chrome", "com.google.Chrome.canary", "com.google.Chrome.beta", "com.google.Chrome.dev":
            return "Google/Chrome"
        case "com.brave.Browser", "com.brave.Browser.beta":
            return "BraveSoftware/Brave-Browser"
        case "com.microsoft.edgemac", "com.microsoft.edgemac.beta", "com.microsoft.edgemac.canary":
            return "Microsoft Edge"
        case "com.vivaldi.Vivaldi":
            return "Vivaldi"
        case "com.operasoftware.Opera":
            return "Opera Software/Opera Stable"
        case "ru.yandex.desktop.yandex-browser":
            return "Yandex/YandexBrowser"
        case "org.chromium.Chromium":
            return "Chromium"
        default:
            return nil
        }
    }
}

public enum BrowserName {
    private static let bundleIDs: [String: String] = [
        "com.apple.Safari": "Safari",
        "com.google.Chrome": "Chrome",
        "com.google.Chrome.canary": "Chrome Canary",
        "com.google.Chrome.beta": "Chrome Beta",
        "com.google.Chrome.dev": "Chrome Dev",
        "org.mozilla.firefox": "Firefox",
        "org.mozilla.firefoxdeveloperedition": "Firefox Developer Edition",
        "org.mozilla.nightly": "Firefox Nightly",
        "com.brave.Browser": "Brave",
        "com.brave.Browser.beta": "Brave Beta",
        "com.microsoft.edgemac": "Microsoft Edge",
        "com.microsoft.edgemac.beta": "Edge Beta",
        "com.microsoft.edgemac.canary": "Edge Canary",
        "com.vivaldi.Vivaldi": "Vivaldi",
        "com.operasoftware.Opera": "Opera",
        "ru.yandex.desktop.yandex-browser": "Yandex",
        "org.chromium.Chromium": "Chromium",
    ]

    private static let bundleIDByName: [String: String] =
        Dictionary(uniqueKeysWithValues: bundleIDs.map { ($0.value.lowercased(), $0.key) })

    public static func displayName(for bundleID: String) -> String {
        bundleIDs[bundleID] ?? bundleID
    }

    public static func bundleID(for name: String) -> String? {
        bundleIDByName[name.lowercased()]
    }
}

public enum ProfileDiscovery {
    public static func chromiumProfileNames(
        bundleID: String,
        localStateURL override: URL? = nil,
        fileManager: FileManager = .default
    ) -> [String: String] {
        let url = override ?? defaultLocalStateURL(bundleID: bundleID, fileManager: fileManager)
        guard let url = url,
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = root["profile"] as? [String: Any],
              let infoCache = profile["info_cache"] as? [String: Any] else {
            return [:]
        }
        var result: [String: String] = [:]
        for (directoryName, value) in infoCache {
            guard let info = value as? [String: Any],
                  let name = info["name"] as? String, !name.isEmpty else { continue }
            result[name.lowercased()] = directoryName
        }
        return result
    }

    public static func resolveChromiumProfile(
        _ name: String,
        bundleID: String,
        localStateURL override: URL? = nil,
        fileManager: FileManager = .default
    ) -> String? {
        let names = chromiumProfileNames(bundleID: bundleID, localStateURL: override, fileManager: fileManager)
        if let directory = names[name.lowercased()] {
            return directory
        }
        if name == "Default" || name.hasPrefix("Profile ") {
            return name
        }
        return nil
    }

    static func defaultLocalStateURL(bundleID: String, fileManager: FileManager) -> URL? {
        guard let directory = BrowserFamily.applicationSupportDirectory(bundleID: bundleID) else { return nil }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(directory)/Local State")
    }
}