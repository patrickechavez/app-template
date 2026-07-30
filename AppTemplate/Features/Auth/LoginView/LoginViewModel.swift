//
//  LoginViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    // Pre-filled with dummyjson's sample credentials for convenience.
    var username = "emilys"
    var password = "emilyspass"
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let auth: AuthRepository
    @ObservationIgnored private let session: SessionManager

    init(auth: AuthRepository, session: SessionManager) {
        self.auth = auth
        self.session = session
    }

    var canSubmit: Bool { !username.isEmpty && !password.isEmpty && !isLoading }

    func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let token = try await auth.login(username: username, password: password)
            session.didAuthenticate(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
