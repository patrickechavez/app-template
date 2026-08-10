//
//  DeepLink.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import os

enum DeepLink: Equatable, Sendable {
    case home
    case item(id: Int)
    case profile
    case settings
    case resetPassword(token: String)

    var isPublic: Bool {
        switch self {
        case .resetPassword: true
        case .home, .item, .profile, .settings: false
        }
    }

    var path: String {
        switch self {
        case .home: "/home"
        case let .item(id): "/items/\(id)"
        case .profile: "/profile"
        case .settings: "/settings"
        case .resetPassword: "/reset-password"
        }
    }
}

struct DeepLinkParser: Sendable {

    private let scheme: String
    private let universalLinkHosts: Set<String>

    init(
        scheme: String = APIConfig.urlScheme,
        universalLinkHosts: Set<String> = ["example.com", "www.example.com"]
    ) {
        self.scheme = scheme.lowercased()
        self.universalLinkHosts = universalLinkHosts
    }

    func parse(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        let incomingScheme = components.scheme?.lowercased()

        let segments: [String]
        switch incomingScheme {
        case scheme:
            segments = ([components.host] + components.path.split(separator: "/").map(String.init))
                .compactMap { $0 }
                .filter { !$0.isEmpty }

        case "https", "http":
            guard let host = components.host?.lowercased(), universalLinkHosts.contains(host) else {
                return nil
            }
            segments = components.path.split(separator: "/").map(String.init)

        default:
            return nil
        }

        return route(for: segments, query: components.queryItems ?? [])
    }

    private func route(for segments: [String], query: [URLQueryItem]) -> DeepLink? {
        func value(_ name: String) -> String? {
            query.first { $0.name == name }?.value
        }

        switch segments.first?.lowercased() {
        case nil, "home", "":
            return .home

        case "items", "item", "products":

            guard segments.count > 1 else { return .home }
            guard let id = Int(segments[1]) else { return nil }
            return .item(id: id)

        case "profile", "me", "account":
            return .profile

        case "settings":
            return .settings

        case "reset-password", "reset":

            guard let token = segments.dropFirst().first ?? value("token"), !token.isEmpty else {
                return nil
            }
            return .resetPassword(token: token)

        default:
            let path = segments.joined(separator: "/")
            AppLogger.navigation.notice("Unrecognised deep link path: \(path, privacy: .public)")
            return nil
        }
    }

    func parse(notificationPayload: [AnyHashable: Any]) -> DeepLink? {
        guard let raw = (payloadValue(notificationPayload, "deep_link")
            ?? payloadValue(notificationPayload, "url")
            ?? payloadValue(notificationPayload, "link")),
            let url = URL(string: raw)
        else {
            return nil
        }
        return parse(url)
    }

    private func payloadValue(_ payload: [AnyHashable: Any], _ key: String) -> String? {
        if let value = payload[key] as? String { return value }

        if let nested = payload["data"] as? [AnyHashable: Any] {
            return nested[key] as? String
        }
        return nil
    }
}
