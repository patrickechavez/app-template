//
//  RetryPolicy.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

struct RetryPolicy: Sendable, Equatable {

    var maxAttempts: Int

    var baseDelay: Duration

    var maxDelay: Duration

    var jitter: ClosedRange<Double>

    init(
        maxAttempts: Int = 3,
        baseDelay: Duration = .milliseconds(500),
        maxDelay: Duration = .seconds(8),
        jitter: ClosedRange<Double> = 0.8...1.2
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitter = jitter
    }

    static let none = RetryPolicy(maxAttempts: 1)

    static let standard = RetryPolicy()

    func shouldRetry(_ error: APIError, attempt: Int, method: HTTPMethod, sentBody: Bool) -> Bool {
        guard attempt < maxAttempts, error.isRetryable else { return false }

        if method.isIdempotent { return true }

        switch error {
        case .offline:
            return true
        default:
            return !sentBody
        }
    }

    func delay(afterAttempt attempt: Int, error: APIError) -> Duration {
        if case let .rateLimited(retryAfter?, _) = error, retryAfter > 0 {
            return min(.seconds(retryAfter), maxDelay)
        }

        let exponent = max(0, attempt - 1)
        let multiplier = pow(2.0, Double(exponent))
        let scaled = baseDelay * multiplier
        let capped = min(scaled, maxDelay)

        return capped * Double.random(in: jitter)
    }
}
