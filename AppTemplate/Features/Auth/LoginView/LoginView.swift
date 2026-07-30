//
//  LoginView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @Environment(Router.self) private var router

    init(viewModel: LoginViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                TextField("Username", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $viewModel.password)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.callout)
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Sign In").frame(maxWidth: .infinity)
                }
            }
            .disabled(!viewModel.canSubmit)

            Section {
                Button("Create an account") { router.push(AuthRoute.register) }
                Button("Forgot password?") { router.push(AuthRoute.forgotPassword) }
            }
        }
        .navigationTitle("Welcome")
    }
}
