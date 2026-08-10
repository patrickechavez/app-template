//
//  AuthRepository.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol AuthRepository: Sendable {
    func login(username: String, password: String) async throws -> AuthTokens
    func register(_ request: RegisterRequest) async throws -> RegisterResponse
    func requestPasswordReset(email: String) async throws
    func resetPassword(token: String, newPassword: String) async throws
    func logout(refreshToken: String?) async throws
}

nonisolated struct LiveAuthRepository: AuthRepository {

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func login(username: String, password: String) async throws -> AuthTokens {
        let response: AuthResponse = try await api.post(
            APIRoute.Auth.login,
            body: LoginRequest(username: username, password: password),
            requiresAuth: false
        )
        return response.tokens
    }

    func register(_ request: RegisterRequest) async throws -> RegisterResponse {
        try await api.post(APIRoute.Auth.register, body: request, requiresAuth: false)
    }

    func requestPasswordReset(email: String) async throws {
        try await api.post(
            APIRoute.Auth.requestPasswordReset,
            body: ForgotPasswordRequest(email: email),
            requiresAuth: false
        )
    }

    func resetPassword(token: String, newPassword: String) async throws {
        try await api.post(
            APIRoute.Auth.resetPassword,
            body: ResetPasswordRequest(token: token, password: newPassword),
            requiresAuth: false
        )
    }

    func logout(refreshToken: String?) async throws {

        try await api.post(
            APIRoute.Auth.logout,
            body: LogoutRequest(refreshToken: refreshToken)
        )
    }
}
