//
//  LoginView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct LoginView: View {

    @State private var viewModel: LoginViewModel
    @Environment(Router<AuthRoute>.self) private var router

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case username, password
    }

    init(viewModel: LoginViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                UsernameField(
                    text: $viewModel.username,
                    error: viewModel.usernameError,
                    identifier: AccessibilityID.Auth.usernameField
                )
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

                PasswordField(
                    text: $viewModel.password,
                    error: viewModel.passwordError,
                    identifier: AccessibilityID.Auth.passwordField
                )
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { submit() }

                if let error = viewModel.generalError {
                    InlineErrorText(error)
                        .testID(AccessibilityID.Auth.errorMessage)
                }

                AsyncButton(
                    title: Text("Sign In", comment: "Primary button on the sign-in screen"),
                    isRunning: viewModel.action.isRunning,
                    action: { await viewModel.signIn() }
                )
                .disabled(!viewModel.canSubmit)
                .testID(AccessibilityID.Auth.signInButton)

                HStack {
                    Button {
                        router.push(.register)
                    } label: {
                        Text("Create an account", comment: "Link to the registration screen")
                    }
                    .testID(AccessibilityID.Auth.registerButton)

                    Spacer()

                    Button {
                        router.push(.forgotPassword)
                    } label: {
                        Text("Forgot password?", comment: "Link to the password reset screen")
                    }
                    .testID(AccessibilityID.Auth.forgotPasswordButton)
                }
                .font(Theme.Font.secondary)
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(Theme.Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text("Welcome", comment: "Title of the sign-in screen"))
    }

    private func submit() {
        focusedField = nil
        Task { await viewModel.signIn() }
    }
}

#if DEBUG

#Preview("Sign in") {
    PreviewHost { dependencies in
        NavigationStack {
            LoginView(viewModel: dependencies.makeLoginViewModel())
        }
        .environment(Router<AuthRoute>())
    }
}

#Preview("Sign in — wrong password") {
    PreviewHost(scenario: .failure(.unauthorized(message: "Incorrect username or password."))) { dependencies in
        NavigationStack {
            LoginView(viewModel: dependencies.makeLoginViewModel())
        }
        .environment(Router<AuthRoute>())
    }
}

#endif
