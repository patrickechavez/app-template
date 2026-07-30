//
//  AuthRepository.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol AuthRepository {
    func login(username: String, password: String) async throws -> String
    func register(_ request: RegisterRequest) async throws -> RegisterResponse
    func requestPasswordReset(email: String) async throws
}

final class LiveAuthRepository: AuthRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func login(username: String, password: String) async throws -> String {
        let response: AuthResponse = try await api.post(
            "auth/login",
            body: LoginRequest(username: username, password: password)
        )
        return response.accessToken
    }

    func register(_ request: RegisterRequest) async throws -> RegisterResponse {
        try await api.post("users/add", body: request)
    }

    func requestPasswordReset(email: String) async throws {
        // dummyjson has no reset endpoint; simulate a success after validation.
        guard email.contains("@"), email.contains(".") else {
            throw APIError.server(status: 400, message: "Enter a valid email address.")
        }
        try await Task.sleep(nanoseconds: 400_000_000)
    }
}
