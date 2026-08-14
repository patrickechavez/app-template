//
//  CrashReporting.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol CrashReporting: Sendable {

    func record(_ error: Error)

    func log(_ message: String)

    func setUser(id: String?)
}

struct NoopCrashReporter: CrashReporting {

    func record(_ error: Error) {}

    func log(_ message: String) {}

    func setUser(id: String?) {}
}
