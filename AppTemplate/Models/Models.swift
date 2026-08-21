//
//  Models.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

struct LoginRequest: Encodable, Sendable {
    let username: String
    let password: String
}

struct RefreshRequest: Encodable, Sendable {
    let refreshToken: String
}

struct LogoutRequest: Encodable, Sendable {
    let refreshToken: String?
}

struct ForgotPasswordRequest: Encodable, Sendable {
    let email: String
}

struct ResetPasswordRequest: Encodable, Sendable {
    let token: String
    let password: String
}

struct AuthResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval?

    var tokens: AuthTokens {
        AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresIn.map { Date().addingTimeInterval($0) }
        )
    }
}

struct RegisterRequest: Encodable, Sendable {
    let firstName: String
    let lastName: String
    let email: String
    let username: String
    let password: String
}

struct RegisterResponse: Decodable, Sendable {
    let id: Int
    let username: String
}

struct User: Codable, Identifiable, Equatable, Sendable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let image: String?

    var fullName: String {

        PersonNameComponents(givenName: firstName, familyName: lastName).formatted()
    }

    var initials: String {
        [firstName, lastName]
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    var avatarURL: URL? {
        image.flatMap(URL.init(string:))
    }
}

// Holds version information for checking if the app needs an update.
struct VersionCheck: Decodable, Sendable {

    let minimumVersion: String

    let latestVersion: String?
    let message: String?

    let isMandatory: Bool

    enum CodingKeys: String, CodingKey {
        case minimumVersion = "minimum_version"
        case latestVersion = "latest_version"
        case message
        case isMandatory = "is_mandatory"
    }
}

struct DeviceRegistration: Encodable, Sendable {
    let token: String
    let platform: String
    let appVersion: String
    let locale: String

    init(pushToken: String) {
        self.token = pushToken
        self.platform = ClientMetadata.platform
        self.appVersion = ClientMetadata.appVersion
        self.locale = Locale.current.identifier
    }
}

struct Item: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let thumbnail: String?

    var thumbnailURL: URL? {
        thumbnail.flatMap(URL.init(string:))
    }
}

struct ItemDraft: Encodable, Sendable {
    let title: String
    let description: String
    let price: Double
}
