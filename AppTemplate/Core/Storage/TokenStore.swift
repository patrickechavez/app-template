//
//  TokenStore.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Security

/// Secure storage for the authentication token.
protocol TokenStore {
    var token: String? { get }
    func save(_ token: String)
    func clear()
}

/// Keychain-backed store — the production implementation.
final class KeychainTokenStore: TokenStore {
    private let service = "com.patrick.AppTemplate"
    private let account = "auth.token"

    var token: String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(_ token: String) {
        SecItemDelete(baseQuery as CFDictionary)
        var attributes = baseQuery
        attributes[kSecValueData as String] = Data(token.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

/// In-memory store for unit tests.
final class InMemoryTokenStore: TokenStore {
    private(set) var token: String?
    init(token: String? = nil) { self.token = token }
    func save(_ token: String) { self.token = token }
    func clear() { token = nil }
}
