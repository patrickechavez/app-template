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
        ScrollView {
            VStack(spacing: 16) {
                UsernameField(text: $viewModel.username)
                PasswordField(text: $viewModel.password)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit)
                .padding(.top, 4)

                HStack {
                    Button("Create an account") { router.push(AuthRoute.register) }
                    Spacer()
                    Button("Forgot password?") { router.push(AuthRoute.forgotPassword) }
                }
                .font(.callout)
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Welcome")
    }
}
