//
//  ForgotPasswordViewModel.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ForgotPasswordViewModel {

    var email = ""
    let action = ActionState()

    private(set) var didSend = false

    @ObservationIgnored private let auth: any AuthRepository

    init(auth: any AuthRepository) {
        self.auth = auth
    }

    var canSubmit: Bool {
        email.trimmed.isValidEmail && !action.isRunning
    }

    var emailError: String? {
        if let serverMessage = action.message(for: "email") { return serverMessage }
        guard !email.isEmpty, !email.trimmed.isValidEmail else { return nil }
        return String(
            localized: "Enter a valid email address.",
            comment: "Validation message shown for a malformed email address"
        )
    }

    var generalError: String? {
        guard action.error?.validationErrors == nil else { return nil }
        return action.errorMessage
    }

    var confirmation: String {
        String(
            localized: "If an account exists for that address, we've sent a link to reset your password.",
            comment: "Confirmation shown after requesting a password reset"
        )
    }

    func submit() async {
        guard canSubmit else { return }

        let address = email.trimmed
        let result: Void? = await action.run { [auth] in
            try await auth.requestPasswordReset(email: address)
        }
        guard result != nil else { return }

        didSend = true
    }
}
