import AppKit
import SwiftUI

// MARK: - Theme

enum Theme {
    // NSColor (for CG rendering)
    static let primary = NSColor(red: 0.851, green: 0.467, blue: 0.341, alpha: 1) // #D97757
    static let danger  = NSColor(red: 0.949, green: 0.247, blue: 0.247, alpha: 1) // #F23F3F
    static let dimmed  = NSColor(white: 0.6, alpha: 0.4)

    // SwiftUI Color equivalents
    static let primarySUI = Color(red: 0.851, green: 0.467, blue: 0.341)
    static let dangerSUI  = Color(red: 0.949, green: 0.247, blue: 0.247)

    static func usageColor(frac: Double, threshold: Double) -> NSColor {
        frac < threshold ? primary : danger
    }

    static func usageColorSUI(frac: Double, threshold: Double) -> Color {
        frac < threshold ? primarySUI : dangerSUI
    }
}

// MARK: - Layout

enum Layout {
    static let menuBarIcon = NSSize(width: 25, height: 18)
    static let popoverIcon = NSSize(width: 70, height: 50)
}

// MARK: - Paths

enum Paths {
    static let stateFile = NSHomeDirectory() + "/.claude/usage-bar-state.json"
    static let daemonPidFile = NSHomeDirectory() + "/.claude/usage-bar-daemon.pid"
}

// MARK: - Settings

/**
 * Centralised access to UserDefaults-backed settings.
 * Matches plasmoid config keys: refreshInterval, warningThreshold, showPercentLabel.
 */
enum AppSettings {
    static let defaultRefreshInterval  = 5
    static let defaultWarningThreshold = 75
    static let defaultShowPercentLabel = true

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "refreshInterval":  defaultRefreshInterval,
            "warningThreshold": defaultWarningThreshold,
            "showPercentLabel": defaultShowPercentLabel,
        ])
    }

    static var refreshInterval: Int {
        max(2, min(120, UserDefaults.standard.integer(forKey: "refreshInterval")))
    }

    // Returns 0.0–1.0 fraction
    static var warningThreshold: Double {
        Double(max(50, min(100, UserDefaults.standard.integer(forKey: "warningThreshold")))) / 100.0
    }

    static var showPercentLabel: Bool {
        UserDefaults.standard.bool(forKey: "showPercentLabel")
    }
}

// MARK: - Date utils

enum DateUtils {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    private static let isoFormatterFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func parseISO(_ iso: String) -> Date? {
        isoFormatter.date(from: iso) ?? isoFormatterFractional.date(from: iso)
    }

    static func formatResets(_ iso: String) -> String {
        guard let date = parseISO(iso) else { return "" }
        let mins = max(0, Int(date.timeIntervalSinceNow / 60))
        return "Resets in \(mins / 60)h \(String(format: "%02d", mins % 60))m"
    }

    static func formatAge(_ iso: String) -> String {
        guard let date = parseISO(iso) else { return "" }
        let age = max(0, Int(-date.timeIntervalSinceNow))
        if age < 60   { return "updated \(age)s ago" }
        if age < 3600 { return "updated \(age / 60)m ago" }
        return "updated \(age / 3600)h ago"
    }
}
