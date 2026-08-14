//
//  Observability.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

/// Ambient access to the observability seams, for the two generic error funnels
/// — `LoadableViewModel.perform` and `ActionState.run` — which are reached
/// through a protocol extension and a shared class, neither of which has an
/// injection point.
///
/// Everywhere else, take the dependency explicitly from `AppDependencies`.
/// `AppDependencies.live()` installs the Firebase adapters here; previews and
/// tests leave the no-ops in place, so nothing reaches the network.
@MainActor
enum Observability {

    static var analytics: any AnalyticsTracking = NoopAnalyticsTracker()

    static var crashes: any CrashReporting = NoopCrashReporter()

    static func install(analytics: any AnalyticsTracking, crashes: any CrashReporting) {
        Self.analytics = analytics
        Self.crashes = crashes
    }
}
