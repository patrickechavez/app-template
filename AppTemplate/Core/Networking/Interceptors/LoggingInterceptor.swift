//
//  LoggingInterceptor.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import os

struct LoggingInterceptor: RequestInterceptor {

    private static let redactedHeaders: Set<String> = [
        "authorization", "cookie", "set-cookie", "x-api-key", "proxy-authorization",
    ]

    private static let redactedBodyKeys: Set<String> = [
        "password", "current_password", "new_password", "password_confirmation",
        "token", "access_token", "refresh_token", "secret", "otp", "pin", "code",
    ]

    private static let maxBodyBytes = 4_000

    private let isEnabled: Bool

    init(isEnabled: Bool = APIConfig.isLoggingEnabled) {
        self.isEnabled = isEnabled
    }

    func adapt(_ request: URLRequest, for endpoint: Endpoint) async throws -> URLRequest {
        guard isEnabled else { return request }

        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        let headers = Self.describe(headers: request.allHTTPHeaderFields ?? [:])
        let body = request.httpBody.map {
            "\n  body: \(Self.describe(body: $0, contentType: endpoint.body?.contentType))"
        } ?? ""

        AppLogger.network.debug(
            """
            → \(method, privacy: .public) \(url, privacy: .public)
              headers: \(headers, privacy: .public)\(body, privacy: .public)
            """
        )
        return request
    }

    func didReceive(_ response: HTTPURLResponse, data: Data, for endpoint: Endpoint) async {
        guard isEnabled else { return }

        let status = response.statusCode
        let url = response.url?.absoluteString ?? endpoint.path
        let body = Self.describe(body: data, contentType: response.value(forHTTPHeaderField: "Content-Type"))
        let symbol = (200..<300).contains(status) ? "✓" : "✗"

        let message = """
        ← \(symbol) \(status) \(url)
          body: \(body)
        """

        if (200..<300).contains(status) {
            AppLogger.network.debug("\(message, privacy: .public)")
        } else {
            AppLogger.network.error("\(message, privacy: .public)")
        }
    }

    private static func describe(headers: [String: String]) -> String {
        guard !headers.isEmpty else { return "none" }

        return headers
            .sorted { $0.key < $1.key }
            .map { key, value in
                redactedHeaders.contains(key.lowercased())
                    ? "\(key): <redacted>"
                    : "\(key): \(value)"
            }
            .joined(separator: ", ")
    }

    private static func describe(body: Data, contentType: String?) -> String {
        guard !body.isEmpty else { return "<empty>" }

        if let contentType, contentType.contains("multipart/form-data") {
            return "<multipart, \(body.count) bytes>"
        }

        guard body.count <= maxBodyBytes else {
            return "<\(body.count) bytes — too large to log>"
        }

        if let object = try? JSONSerialization.jsonObject(with: body) {
            let redacted = redact(object)
            if let data = try? JSONSerialization.data(withJSONObject: redacted, options: [.sortedKeys]),
               let text = String(data: data, encoding: .utf8) {
                return text
            }
        }

        guard let text = String(data: body, encoding: .utf8) else {
            return "<\(body.count) bytes, not UTF-8>"
        }
        return text
    }

    private static func redact(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, entry in
                result[entry.key] = redactedBodyKeys.contains(entry.key.lowercased())
                    ? "<redacted>"
                    : redact(entry.value)
            }
        }
        if let array = value as? [Any] {
            return array.map(redact)
        }
        return value
    }
}
