//
//  RegisterViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class RegisterViewModel {
    var firstName = ""
    var lastName = ""
    var email = ""
    var username = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    var didRegister = false

    @ObservationIgnored private let auth: AuthRepository

    init(auth: AuthRepository) {
        self.auth = auth
    }

    var canSubmit: Bool {
        !firstName.isEmpty && !email.isEmpty && !username.isEmpty
            && !password.isEmpty && !isLoading
    }

    func register() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await auth.register(
                RegisterRequest(firstName: firstName,
                                lastName: lastName,
                                email: email,
                                username: username,
                                password: password)
            )
            didRegister = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
