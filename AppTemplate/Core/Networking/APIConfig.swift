//
//  APIConfig.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum APIConfig {

    static let baseURL: URL = {
        guard let value = string("API_BASE_URL"), let url = URL(string: value) else {
            preconditionFailure(
                """
                API_BASE_URL is missing or invalid in Info.plist.
                Set it in Config/<Environment>.xcconfig — remember to escape the \
                double slash as `https:/$()/example.com`.
                """
            )
        }
        return url
    }()

    static let timeout: TimeInterval = double("API_TIMEOUT_SECONDS") ?? 30

    static let maxAttempts: Int = int("API_MAX_RETRIES").map { $0 + 1 } ?? 3

    static let isLoggingEnabled: Bool = bool("API_LOGGING_ENABLED")

    static let isForceUpdateEnabled: Bool = bool("FORCE_UPDATE_ENABLED")

    static var retryPolicy: RetryPolicy {
        maxAttempts <= 1 ? .none : RetryPolicy(maxAttempts: maxAttempts)
    }

    static let urlScheme: String = string("APP_URL_SCHEME") ?? "apptemplate"

    private static func string(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func int(_ key: String) -> Int? { string(key).flatMap(Int.init) }

    private static func double(_ key: String) -> Double? { string(key).flatMap(Double.init) }

    private static func bool(_ key: String) -> Bool {
        switch string(key)?.uppercased() {
        case "YES", "TRUE", "1": true
        default: false
        }
    }
}
