//
//  UserRepository.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol UserRepository {
    func currentUser() async throws -> User
}

final class LiveUserRepository: UserRepository {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    /// Uses the stored token (attached automatically by the client).
    func currentUser() async throws -> User {
        try await api.get("auth/me")
    }
}
