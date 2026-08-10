//
//  AuthTokens.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

struct AuthTokens: Codable, Sendable, Equatable {

    let accessToken: String

    let refreshToken: String?

    let expiresAt: Date?

    init(accessToken: String, refreshToken: String? = nil, expiresAt: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }

    var needsProactiveRefresh: Bool {
        guard let expiresAt else { return false }
        return expiresAt.timeIntervalSinceNow < 60
    }

    var canRefresh: Bool {
        !(refreshToken ?? "").isEmpty
    }
}
