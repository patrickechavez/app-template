//
//  ClientMetadata.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

/// Supplies the metadata headers attached to every outgoing request.
///
/// A protocol so the API client depends on the abstraction (not a global),
/// matching the app's dependency-injection pattern — a stub can be injected in
/// tests.
protocol RequestMetadataProviding {
    var headers: [String: String] { get }
}

/// App + device metadata sent as `X-*` headers.
///
/// Single source of truth: each value is defined once and the header set is
/// built from those values. Everything is read once (static `let`) since it
/// can't change during a session, then reused for all requests.
struct ClientMetadata: RequestMetadataProviding {

    var headers: [String: String] { Self.cachedHeaders }

    private static let cachedHeaders: [String: String] = [
        "X-App-Version": appVersion,
        "X-App-Build": appBuild,
        "X-Platform": platform,
        "X-OS-Version": osVersion,
        "X-Device-Model": deviceModel
    ]

    /// Marketing version, e.g. "1.2.0".
    static let appVersion = bundleValue("CFBundleShortVersionString")

    /// Build number, e.g. "45".
    static let appBuild = bundleValue("CFBundleVersion")

    /// Platform name — handy once an Android/Web client also exists.
    static let platform = "iOS"

    /// OS version the user is running, e.g. "17.4".
    static let osVersion: String = {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let base = "\(v.majorVersion).\(v.minorVersion)"
        return v.patchVersion > 0 ? "\(base).\(v.patchVersion)" : base
    }()

    /// Hardware identifier, e.g. "iPhone15,2".
    ///
    /// `UIDevice.current.model` only returns "iPhone", so the real identifier
    /// is read from `uname`. On the Simulator that returns the host arch, so we
    /// prefer the Simulator's own model identifier when present.
    static let deviceModel: String = {
        if let simulator = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulator
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }()

    private static func bundleValue(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "unknown"
    }
}
