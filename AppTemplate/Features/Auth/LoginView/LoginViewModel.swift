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

    init(auth: any AuthRepository, session: SessionManager) {
        self.auth = auth
        self.session = session
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

        let credentials = (username: username.trimmed, password: password)
        let tokens = await action.run { [auth] in
            try await auth.login(username: credentials.username, password: credentials.password)
        }

        guard let tokens else { return }

        password = ""
        await session.didAuthenticate(tokens: tokens)
    }
}

extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
