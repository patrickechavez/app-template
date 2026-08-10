//
//  TokenRefreshCoordinator.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import os

protocol TokenRefreshing: Sendable {
    func refresh(using refreshToken: String) async throws -> AuthTokens
}

actor TokenRefreshCoordinator {

    private let store: any TokenStore
    private let refresher: any TokenRefreshing
    private let events: SessionEventBus

    private var inFlight: Task<AuthTokens, any Error>?

    init(store: any TokenStore, refresher: any TokenRefreshing, events: SessionEventBus) {
        self.store = store
        self.refresher = refresher
        self.events = events
    }

    func currentTokens() async -> AuthTokens? {
        await store.load()
    }

    @discardableResult
    func refresh(staleAccessToken: String?) async throws -> AuthTokens {

        if let inFlight {
            return try await inFlight.value
        }

        let task = Task<AuthTokens, any Error> { [refresher, store] in
            guard let current = await store.load() else {
                throw APIError.unauthorized()
            }

            if let staleAccessToken, current.accessToken != staleAccessToken {
                return current
            }

            guard let refreshToken = current.refreshToken, !refreshToken.isEmpty else {

                AppLogger.auth.notice("401 with no refresh token available — ending session.")
                throw APIError.unauthorized()
            }

            AppLogger.auth.notice("Refreshing access token")
            let renewed = try await refresher.refresh(using: refreshToken)
            try await store.save(renewed)
            return renewed
        }
        inFlight = task

        do {
            let renewed = try await task.value
            inFlight = nil
            AppLogger.auth.notice("Access token refreshed")
            return renewed
        } catch {
            inFlight = nil

            if error is CancellationError || (error as? APIError) == .cancelled {
                throw APIError.cancelled
            }

            AppLogger.auth.error(
                "Token refresh failed: \(error.localizedDescription, privacy: .public) — ending session."
            )
            await invalidate()
            throw APIError.unauthorized()
        }
    }

    func invalidate() async {
        await store.clear()
        events.send(.expired)
    }
}

struct LiveTokenRefresher: TokenRefreshing {

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func refresh(using refreshToken: String) async throws -> AuthTokens {
        let response: AuthResponse = try await api.post(
            APIRoute.Auth.refresh,
            body: RefreshRequest(refreshToken: refreshToken),
            requiresAuth: false
        )
        return response.tokens
    }
}
