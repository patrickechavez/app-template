//
//  ForgotPasswordViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ForgotPasswordViewModel {
    var email = ""
    var isLoading = false
    var errorMessage: String?
    var didSend = false

    @ObservationIgnored private let auth: AuthRepository

    init(auth: AuthRepository) {
        self.auth = auth
    }

    var canSubmit: Bool { !email.isEmpty && !isLoading }

    func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.requestPasswordReset(email: email)
            didSend = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
