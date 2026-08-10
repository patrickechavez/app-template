//
//  RegisterViewModel.swift
//  AppTemplate
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

    let action = ActionState()

    private(set) var didRegister = false

    @ObservationIgnored private let auth: any AuthRepository

    private static let minimumPasswordLength = 8

    init(auth: any AuthRepository) {
        self.auth = auth
    }

    var firstNameError: String? { action.message(for: "firstName") }
    var lastNameError: String? { action.message(for: "lastName") }
    var usernameError: String? { action.message(for: "username") }

    var emailError: String? {
        if let serverMessage = action.message(for: "email") { return serverMessage }
        guard !email.isEmpty, !email.trimmed.isValidEmail else { return nil }
        return String(
            localized: "Enter a valid email address.",
            comment: "Validation message shown for a malformed email address"
        )
    }

    var passwordError: String? {
        if let serverMessage = action.message(for: "password") { return serverMessage }
        guard !password.isEmpty, password.count < Self.minimumPasswordLength else { return nil }
        return String(
            localized: "Use at least \(Self.minimumPasswordLength) characters.",
            comment: "Validation message shown when a password is too short"
        )
    }

    var generalError: String? {
        guard action.error?.validationErrors == nil else { return nil }
        return action.errorMessage
    }

    var canSubmit: Bool {
        !action.isRunning
            && !firstName.trimmed.isEmpty
            && !lastName.trimmed.isEmpty
            && !username.trimmed.isEmpty
            && email.trimmed.isValidEmail
            && password.count >= Self.minimumPasswordLength
    }

    func submit() async {
        guard canSubmit else { return }

        let request = RegisterRequest(
            firstName: firstName.trimmed,
            lastName: lastName.trimmed,
            email: email.trimmed,
            username: username.trimmed,
            password: password
        )

        let response = await action.run { [auth] in
            try await auth.register(request)
        }
        guard response != nil else { return }

        password = ""
        didRegister = true
    }
}

extension String {

    var isValidEmail: Bool {
        guard !isEmpty, !contains(" "), count <= 254 else { return false }

        let parts = split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }

        let domain = parts[1]
        return domain.contains(".")
            && !domain.hasPrefix(".")
            && !domain.hasSuffix(".")
            && !domain.contains("..")
    }
}
