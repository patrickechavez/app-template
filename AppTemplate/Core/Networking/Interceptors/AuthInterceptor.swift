//
//  AuthInterceptor.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import os

struct AuthInterceptor: RequestInterceptor {

    private let coordinator: TokenRefreshCoordinator

    init(coordinator: TokenRefreshCoordinator) {
        self.coordinator = coordinator
    }

    func adapt(_ request: URLRequest, for endpoint: Endpoint) async throws -> URLRequest {
        guard endpoint.requiresAuth else { return request }

        var tokens = await coordinator.currentTokens()

        if let current = tokens, current.needsProactiveRefresh, current.canRefresh {
            tokens = try? await coordinator.refresh(staleAccessToken: current.accessToken)
        }

        guard let accessToken = tokens?.accessToken, !accessToken.isEmpty else {

            return request
        }

        var request = request
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    func handle(_ error: APIError, for endpoint: Endpoint, attempt: Int) async -> InterceptorDecision {
        guard case .unauthorized = error, endpoint.requiresAuth else { return .proceed }

        let current = await coordinator.currentTokens()

        guard let current, current.canRefresh else {
            AppLogger.auth.notice(
                "401 on \(endpoint.path, privacy: .public) with no way to refresh — ending session."
            )
            await coordinator.invalidate()
            return .fail(error)
        }

        do {
            try await coordinator.refresh(staleAccessToken: current.accessToken)

            return .retry
        } catch let refreshError {

            if (refreshError as? APIError) == .cancelled {
                return .fail(.cancelled)
            }

            return .fail(error)
        }
    }
}

struct SessionPolicyInterceptor: RequestInterceptor {

    private let events: SessionEventBus

    init(events: SessionEventBus) {
        self.events = events
    }

    func handle(_ error: APIError, for endpoint: Endpoint, attempt: Int) async -> InterceptorDecision {
        switch error {
        case let .updateRequired(message):
            events.send(.updateRequired(message: message))
        case let .maintenance(message):
            events.send(.maintenance(message: message))
        default:
            break
        }

        return .proceed
    }
}
