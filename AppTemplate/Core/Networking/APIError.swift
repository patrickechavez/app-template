//
//  APIError.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

struct ValidationErrors: Sendable, Equatable {

    let fields: [String: [String]]

    let summary: String?

    func first(for field: String) -> String? {
        fields[field]?.first
    }

    var allMessages: [String] {

        fields.sorted { $0.key < $1.key }.flatMap(\.value)
    }
}

enum APIError: LocalizedError, Equatable, Sendable {

    case offline

    case timedOut

    case cancelled

    case transport(detail: String)

    case serverTrustFailed

    case invalidURL

    case invalidResponse

    case decodingFailed(detail: String)

    case unauthorized(message: String? = nil)

    case forbidden(message: String? = nil)

    case notFound(message: String? = nil)

    case conflict(message: String? = nil)

    case validation(ValidationErrors)

    case rateLimited(retryAfter: TimeInterval? = nil, message: String? = nil)

    case updateRequired(message: String? = nil)

    case maintenance(message: String? = nil)

    case server(status: Int, message: String? = nil)

    var errorDescription: String? {
        switch self {
        case .offline:
            String(localized: "You appear to be offline. Check your connection and try again.",
                   comment: "Error shown when the device has no network connection")

        case .timedOut:
            String(localized: "The request took too long. Please try again.",
                   comment: "Error shown when a network request times out")

        case .cancelled:

            String(localized: "Cancelled.", comment: "A request was cancelled")

        case .transport:
            String(localized: "We couldn't reach the server. Please try again.",
                   comment: "Generic network transport failure")

        case .serverTrustFailed:
            String(localized: "We couldn't establish a secure connection. Please try again.",
                   comment: "Error shown when the server's certificate fails trust validation")

        case .invalidURL, .invalidResponse, .decodingFailed:

            String(localized: "Something went wrong. Please try again.",
                   comment: "Generic error for an unexpected response")

        case let .unauthorized(message):
            message ?? String(localized: "Your session has expired. Please sign in again.",
                              comment: "Error shown when the session is no longer valid")

        case let .forbidden(message):
            message ?? String(localized: "You don't have permission to do that.",
                              comment: "Error shown when the user lacks permission")

        case let .notFound(message):
            message ?? String(localized: "We couldn't find what you were looking for.",
                              comment: "Error shown when a resource does not exist")

        case let .conflict(message):
            message ?? String(localized: "That conflicts with something that already exists.",
                              comment: "Error shown on a 409 conflict")

        case let .validation(errors):
            errors.summary
                ?? errors.allMessages.first
                ?? String(localized: "Please check the highlighted fields.",
                          comment: "Error shown when form validation fails server-side")

        case let .rateLimited(_, message):
            message ?? String(localized: "Too many attempts. Please wait a moment and try again.",
                              comment: "Error shown when rate limited")

        case let .updateRequired(message):
            message ?? String(localized: "This version of the app is no longer supported. Please update.",
                              comment: "Error shown when the app build is too old for the API")

        case let .maintenance(message):
            message ?? String(localized: "The service is temporarily unavailable for maintenance.",
                              comment: "Error shown when the backend is in maintenance mode")

        case let .server(_, message):
            message ?? String(localized: "Something went wrong on our end. Please try again.",
                              comment: "Generic server error")
        }
    }

    var statusCode: Int? {
        switch self {
        case .unauthorized: 401
        case .forbidden: 403
        case .notFound: 404
        case .conflict: 409
        case .validation: 422
        case .rateLimited: 429
        case .updateRequired: 426
        case .maintenance: 503
        case let .server(status, _): status
        default: nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .offline, .timedOut, .transport, .rateLimited, .maintenance:
            true
        case let .server(status, _):

            status >= 500
        case .cancelled, .invalidURL, .invalidResponse, .decodingFailed, .serverTrustFailed,
             .unauthorized, .forbidden, .notFound, .conflict, .validation, .updateRequired:
            false
        }
    }

    var invalidatesSession: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    var validationErrors: ValidationErrors? {
        if case let .validation(errors) = self { return errors }
        return nil
    }

    var isUserFacing: Bool {
        if case .cancelled = self { return false }
        return true
    }

    /// A stable, low-cardinality label for analytics. Deliberately drops the
    /// associated values — server messages and validation details can carry
    /// user data, which has no business in an analytics payload.
    var analyticsReason: String {
        switch self {
        case .offline: "offline"
        case .timedOut: "timed_out"
        case .cancelled: "cancelled"
        case .transport: "transport"
        case .serverTrustFailed: "server_trust_failed"
        case .invalidURL: "invalid_url"
        case .invalidResponse: "invalid_response"
        case .decodingFailed: "decoding_failed"
        case .unauthorized: "unauthorized"
        case .forbidden: "forbidden"
        case .notFound: "not_found"
        case .conflict: "conflict"
        case .validation: "validation"
        case .rateLimited: "rate_limited"
        case .updateRequired: "update_required"
        case .maintenance: "maintenance"
        case let .server(status, _): "server_\(status)"
        }
    }

    /// Errors that mean the app or the backend is broken, as opposed to a
    /// network condition or a rejection the user can act on. Only these are
    /// worth a non-fatal crash report — the rest would drown it in noise.
    var isWorthReporting: Bool {
        switch self {
        case .invalidURL, .invalidResponse, .decodingFailed, .serverTrustFailed:
            true
        case let .server(status, _):
            status >= 500
        case .offline, .timedOut, .cancelled, .transport, .unauthorized, .forbidden,
             .notFound, .conflict, .validation, .rateLimited, .updateRequired, .maintenance:
            false
        }
    }

    static func from(transportError error: any Error) -> APIError {
        if error is CancellationError { return .cancelled }

        guard let urlError = error as? URLError else {
            return .transport(detail: String(describing: error))
        }

        return switch urlError.code {
        case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff:
            .offline
        case .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:

            .transport(detail: urlError.localizedDescription)
        case .timedOut:
            .timedOut
        case .cancelled:
            .cancelled
        case .serverCertificateUntrusted, .serverCertificateHasBadDate,
             .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot:
            .serverTrustFailed
        default:
            .transport(detail: urlError.localizedDescription)
        }
    }

    static func from(statusCode: Int, data: Data, headers: [AnyHashable: Any] = [:]) -> APIError {
        let body = APIErrorBody(data: data)
        let message = body.message

        switch statusCode {
        case 401:
            return .unauthorized(message: message)
        case 403:
            return .forbidden(message: message)
        case 404:
            return .notFound(message: message)
        case 409:
            return .conflict(message: message)
        case 422:
            return .validation(ValidationErrors(fields: body.fieldErrors, summary: message))
        case 400 where !body.fieldErrors.isEmpty:

            return .validation(ValidationErrors(fields: body.fieldErrors, summary: message))
        case 426:
            return .updateRequired(message: message)
        case 429:
            let retryAfter = (headers["Retry-After"] as? String).flatMap(TimeInterval.init)
            return .rateLimited(retryAfter: retryAfter, message: message)
        case 503:
            return .maintenance(message: message)
        default:
            return .server(status: statusCode, message: message)
        }
    }
}
