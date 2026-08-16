//
//  JailbreakDetector.swift
//  AppTemplate
//  Created by John Patrick Echavez on 8/16/26.
//

import Foundation

protocol JailbreakDetecting: Sendable {
    var isJailbroken: Bool { get }
}

/// Heuristic jailbreak detection via filesystem indicators. Detect-and-report
/// only: it is bypassable and can false-positive, so it flags devices in
/// analytics rather than acting as a security boundary.
struct DefaultJailbreakDetector: JailbreakDetecting {

    private let indicators = [
        "/Applications/Cydia.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/Applications/Filza.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/usr/sbin/sshd",
        "/usr/bin/ssh",
        "/bin/bash",
        "/etc/apt",
        "/private/var/lib/apt",
        "/private/var/lib/cydia",
        "/private/var/stash",
    ]

    var isJailbroken: Bool {
        indicators.contains { FileManager.default.fileExists(atPath: $0) }
    }
}
