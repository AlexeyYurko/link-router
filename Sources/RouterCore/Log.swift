import Foundation

public enum Log {
    public static func redacted(_ urlString: String) -> String {
        guard let cut = urlString.firstIndex(where: { $0 == "?" || $0 == "#" }) else { return urlString }
        return String(urlString[..<cut]) + "…"
    }

    public static func write(_ message: String, suffix: String = "LinkRouter.log") {
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)"
        fputs(line + "\n", stderr)
        let fileManager = FileManager.default
        let url = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/\(suffix)")
        guard let data = (line + "\n").data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(data)
        } else {
            try? data.write(to: url)
        }
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}