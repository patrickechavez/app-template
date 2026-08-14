//
//  FirebaseObservability.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

struct FirebaseAnalyticsTracker: AnalyticsTracking {

    func track(_ event: String, parameters: [String: String]) {
        Analytics.logEvent(event, parameters: parameters.isEmpty ? nil : parameters)
    }

    func setUser(id: String?) {
        Analytics.setUserID(id)
    }
}

struct FirebaseCrashReporter: CrashReporting {

    func record(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }

    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    func setUser(id: String?) {
        Crashlytics.crashlytics().setUserID(id)
    }
}
