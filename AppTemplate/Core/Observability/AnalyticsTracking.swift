//
//  AnalyticsTracking.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol AnalyticsTracking: Sendable {

    func track(_ event: String, parameters: [String: String])

    func setUser(id: String?)
}

extension AnalyticsTracking {

    func track(_ event: String) {
        track(event, parameters: [:])
    }
}

struct NoopAnalyticsTracker: AnalyticsTracking {

    func track(_ event: String, parameters: [String: String]) {}

    func setUser(id: String?) {}
}
