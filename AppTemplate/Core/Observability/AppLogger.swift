//
//  AppLogger.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import OSLog
import os

enum AppLogger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "AppTemplate"

    static let network = Logger(subsystem: subsystem, category: "network")

    static let auth = Logger(subsystem: subsystem, category: "auth")

    static let data = Logger(subsystem: subsystem, category: "data")

    static let images = Logger(subsystem: subsystem, category: "images")

    static let navigation = Logger(subsystem: subsystem, category: "navigation")

    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
}
