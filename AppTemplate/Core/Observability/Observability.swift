//
//  Observability.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

// Handles logging and crash reporting throughout the app.
@MainActor
enum Observability {

    static var analytics: any AnalyticsTracking = NoopAnalyticsTracker()

    static var crashes: any CrashReporting = NoopCrashReporter()

    static func install(analytics: any AnalyticsTracking, crashes: any CrashReporting) {
        Self.analytics = analytics
        Self.crashes = crashes
    }
}
