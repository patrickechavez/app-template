//
//  AccessibilityID.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

enum AccessibilityID {

    enum Auth {
        static let usernameField = "auth.username"
        static let passwordField = "auth.password"
        static let signInButton = "auth.signIn"
        static let registerButton = "auth.register"
        static let forgotPasswordButton = "auth.forgotPassword"
        static let errorMessage = "auth.error"
    }

    enum Register {
        static let firstNameField = "register.firstName"
        static let lastNameField = "register.lastName"
        static let emailField = "register.email"
        static let usernameField = "register.username"
        static let passwordField = "register.password"
        static let submitButton = "register.submit"
    }

    enum Home {
        static let list = "home.list"
        static let searchField = "home.search"
        static func row(_ id: Int) -> String { "home.row.\(id)" }
        static let emptyState = "home.empty"
        static let errorState = "home.error"
        static let retryButton = "home.retry"
    }

    enum ItemDetail {
        static let title = "itemDetail.title"
        static let price = "itemDetail.price"
    }

    enum Profile {
        static let avatar = "profile.avatar"
        static let fullName = "profile.fullName"
        static let email = "profile.email"
        static let changePhotoButton = "profile.changePhoto"
        static let signOutButton = "profile.signOut"
    }

    enum Shell {
        static let tabBar = "shell.tabBar"
        static let launchProgress = "shell.launchProgress"
        static let updateRequired = "shell.updateRequired"
    }
}

extension View {

    func testID(_ identifier: String) -> some View {
        accessibilityIdentifier(identifier)
    }
}
