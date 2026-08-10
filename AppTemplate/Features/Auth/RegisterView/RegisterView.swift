//
//  RegisterView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct RegisterView: View {

    @State private var viewModel: RegisterViewModel
    @Environment(Router<AuthRoute>.self) private var router
    @Environment(\.dismiss) private var dismiss

    init(viewModel: RegisterViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                AppTextField(
                    text: $viewModel.firstName,
                    placeholder: String(localized: "First name", comment: "Placeholder for the first name field"),
                    label: String(localized: "First name", comment: "Label for the first name field"),
                    error: viewModel.firstNameError,
                    isRequired: true,
                    capitalization: .words,
                    contentType: .givenName,
                    identifier: AccessibilityID.Register.firstNameField
                )

                AppTextField(
                    text: $viewModel.lastName,
                    placeholder: String(localized: "Last name", comment: "Placeholder for the last name field"),
                    label: String(localized: "Last name", comment: "Label for the last name field"),
                    error: viewModel.lastNameError,
                    isRequired: true,
                    capitalization: .words,
                    contentType: .familyName,
                    identifier: AccessibilityID.Register.lastNameField
                )

                EmailField(
                    text: $viewModel.email,
                    error: viewModel.emailError,
                    isRequired: true,
                    identifier: AccessibilityID.Register.emailField
                )

                UsernameField(
                    text: $viewModel.username,
                    error: viewModel.usernameError,
                    isRequired: true,
                    identifier: AccessibilityID.Register.usernameField
                )

                PasswordField(
                    text: $viewModel.password,
                    error: viewModel.passwordError,
                    isRequired: true,
                    isNewPassword: true,
                    identifier: AccessibilityID.Register.passwordField
                )

                if let error = viewModel.generalError {
                    InlineErrorText(error)
                }

                AsyncButton(
                    title: Text("Create Account", comment: "Primary button on the registration screen"),
                    isRunning: viewModel.action.isRunning,
                    action: { await viewModel.submit() }
                )
                .disabled(!viewModel.canSubmit)
                .testID(AccessibilityID.Register.submitButton)
            }
            .padding(Theme.Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text("Create Account", comment: "Title of the registration screen"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.didRegister) { _, didRegister in
            guard didRegister else { return }
            router.present(alert: AlertState(
                title: String(localized: "Account created", comment: "Title of the registration success alert"),
                message: String(
                    localized: "You can now sign in with your new account.",
                    comment: "Message of the registration success alert"
                ),
                buttons: [AlertButton(title: String(localized: "OK", comment: "Alert dismiss button")) {
                    dismiss()
                }]
            ))
        }
    }
}

#if DEBUG

#Preview {
    PreviewHost { dependencies in
        NavigationStack {
            RegisterView(viewModel: dependencies.makeRegisterViewModel())
        }
        .environment(Router<AuthRoute>())
    }
}

#endif
