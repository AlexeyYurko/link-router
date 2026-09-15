import Foundation

public enum BrowserLauncher {
    public static let suppressTargets: Set<String> = ["", "none", "null", "suppress"]

    public static func open(url: URL, target: BrowserTarget, fileManager: FileManager = .default) {
        guard !suppressTargets.contains(target.browser.lowercased()) else {
            Log.write("suppressed: \(Log.redacted(url.absoluteString))")
            return
        }
        let command = openCommand(url: url, target: target, fileManager: fileManager)
        let display = command.map { arg -> String in
            let shown = arg == url.absoluteString ? Log.redacted(arg) : arg
            return shown.contains(" ") ? "\"\(shown)\"" : shown
        }
        Log.write("$ \(display.joined(separator: " "))")
        run(command)
    }

    public static func openCommand(
        url: URL,
        target: BrowserTarget,
        fileManager: FileManager = .default
    ) -> [String] {
        var command: [String] = ["/usr/bin/open"]
        var arguments: [String] = []

        if target.browser.contains("/") {
            command += ["-a", target.browser]
            arguments = [url.absoluteString]
        } else {
            switch BrowserFamily(bundleID: target.browser) {
            case .chromium:
                command += ["-n", "-b", target.browser, "--args"]
                if let profile = target.profile {
                    if let directory = ProfileDiscovery.resolveChromiumProfile(
                        profile, bundleID: target.browser, fileManager: fileManager
                    ) {
                        arguments.append("--profile-directory=\(directory)")
                    } else {
                        Log.write("Chromium profile '\(profile)' not found; using default")
                    }
                }
                arguments += [url.absoluteString]
                arguments += target.args ?? []
            case .firefox:
                if target.profile != nil || target.args != nil {
                    command += ["-b", target.browser, "--args"]
                    if let profile = target.profile {
                        arguments += ["-no-remote", "-P", profile]
                    }
                    arguments += [url.absoluteString]
                    arguments += target.args ?? []
                } else {
                    command += ["-b", target.browser]
                    arguments = [url.absoluteString]
                }
            case .safari, .other:
                command += ["-b", target.browser]
                arguments = [url.absoluteString]
            }
        }
        command += arguments
        return command
    }

    private static func run(_ command: [String]) {
        guard let executable = command.first else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = Array(command.dropFirst())
        do {
            try process.run()
        } catch {
            Log.write("launch failed: \(error)")
        }
    }
}