//
//  RegisterViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import UIKit
import Observation

@Observable
@MainActor
final class RegisterViewModel {
    var firstName = ""
    var lastName = ""
    var email = ""
    var username = ""
    var password = ""
    var selectedImage: UIImage?
    var isLoading = false
    var errorMessage: String?
    var didRegister = false

    @ObservationIgnored private let auth: AuthRepository
    @ObservationIgnored private let users: UserRepository

    init(auth: AuthRepository, users: UserRepository) {
        self.auth = auth
        self.users = users
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
            // Avatar is optional: upload it if one was picked, but don't fail
            // registration if the upload errors — the user can add it later.
            if let selectedImage {
                _ = try? await users.uploadAvatar(selectedImage)
            }
            didRegister = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
