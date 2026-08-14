//
//  LoginViewModel.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {

    var username = ""
    var password = ""

    let action = ActionState()

    @ObservationIgnored private let auth: any AuthRepository
    @ObservationIgnored private let session: SessionManager
    @ObservationIgnored private let analytics: any AnalyticsTracking

    init(
        auth: any AuthRepository,
        session: SessionManager,
        analytics: any AnalyticsTracking = NoopAnalyticsTracker()
    ) {
        self.auth = auth
        self.session = session
        self.analytics = analytics
    }

    var canSubmit: Bool {
        !username.trimmed.isEmpty && !password.isEmpty && !action.isRunning
    }

    var usernameError: String? { action.message(for: "username") }
    var passwordError: String? { action.message(for: "password") }

    var generalError: String? {
        guard action.error?.validationErrors == nil else { return nil }
        return action.errorMessage
    }

    func signIn() async {
        guard canSubmit else { return }

        analytics.track("login_attempt")

        let credentials = (username: username.trimmed, password: password)
        let tokens = await action.run { [auth] in
            try await auth.login(username: credentials.username, password: credentials.password)
        }

        guard let tokens else {
            if let error = action.error {
                analytics.track("login_failed", parameters: ["reason": error.analyticsReason])
            }
            return
        }

        analytics.track("login_succeeded")

        password = ""
        await session.didAuthenticate(tokens: tokens)
    }
}

extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
