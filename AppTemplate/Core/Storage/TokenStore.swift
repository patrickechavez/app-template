//
//  TokenStore.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Security
import os

enum KeychainError: LocalizedError, Equatable {
    case unexpectedData
    case unhandled(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedData:
            return "Stored credentials were in an unexpected format."
        case let .unhandled(status):

            let detail = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
            return "Keychain error: \(detail)"
        }
    }
}

protocol TokenStore: Sendable {
    func load() async -> AuthTokens?
    func save(_ tokens: AuthTokens) async throws
    func clear() async
}

actor KeychainTokenStore: TokenStore {

    private let service: String
    private let account = "auth.tokens"

    private var cached: AuthTokens??

    init(service: String? = nil) {
        self.service = service ?? Bundle.main.bundleIdentifier ?? "com.patrick.AppTemplate"
    }

    func load() async -> AuthTokens? {
        if let cached { return cached }

        let tokens = readFromKeychain()
        cached = .some(tokens)
        return tokens
    }

    func save(_ tokens: AuthTokens) async throws {
        let data = try JSONEncoder().encode(tokens)

        let deleteStatus = SecItemDelete(baseQuery as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError.unhandled(status: deleteStatus)
        }

        var attributes = baseQuery
        attributes[kSecValueData as String] = data

        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            AppLogger.auth.error("Keychain write failed: OSStatus \(addStatus, privacy: .public)")
            throw KeychainError.unhandled(status: addStatus)
        }

        cached = .some(tokens)
    }

    func clear() async {
        let status = SecItemDelete(baseQuery as CFDictionary)
        if status != errSecSuccess, status != errSecItemNotFound {

            AppLogger.auth.error("Keychain clear failed: OSStatus \(status, privacy: .public)")
        }
        cached = .some(nil)
    }

    private func readFromKeychain() -> AuthTokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                AppLogger.auth.error("Keychain read failed: OSStatus \(status, privacy: .public)")
            }
            return nil
        }

        guard let data = result as? Data else { return nil }

        do {
            return try JSONDecoder().decode(AuthTokens.self, from: data)
        } catch {

            AppLogger.auth.error("Stored tokens could not be decoded; discarding.")
            SecItemDelete(baseQuery as CFDictionary)
            return nil
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

actor InMemoryTokenStore: TokenStore {

    private var tokens: AuthTokens?

    var saveError: (any Error)?

    init(tokens: AuthTokens? = nil) {
        self.tokens = tokens
    }

    func load() async -> AuthTokens? { tokens }

    func save(_ tokens: AuthTokens) async throws {
        if let saveError { throw saveError }
        self.tokens = tokens
    }

    func clear() async { tokens = nil }

    func setSaveError(_ error: (any Error)?) { saveError = error }
}
