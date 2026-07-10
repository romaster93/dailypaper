//  Config.swift
//  Where the app gets its daily feed. Point `defaultFeedURLString` at wherever your
//  Mac Mini publishes daily.json (see Backend/daily.schema.md). Leave it empty to run
//  entirely on the bundled sample data — the app behaves exactly as before.

import Foundation

enum Config {
    /// Production feed URL. Empty → bundled sample data.
    /// e.g. "https://your-host.example.com/paperdaily/daily.json"
    static let defaultFeedURLString = ""

    /// Effective feed URL, allowing a runtime override for testing via
    /// `SIMCTL_CHILD_PD_FEED_URL=<url>` (env) or `-PD_FEED_URL <url>` (launch arg).
    static var feedURL: URL? {
        let env = ProcessInfo.processInfo.environment
        let override = env["PD_FEED_URL"] ?? UserDefaults.standard.string(forKey: "PD_FEED_URL")
        let raw = (override?.isEmpty == false) ? override! : defaultFeedURLString
        return raw.isEmpty ? nil : URL(string: raw)
    }
}
