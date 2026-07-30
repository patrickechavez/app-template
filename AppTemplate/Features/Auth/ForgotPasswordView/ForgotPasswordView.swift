//
//  ForgotPasswordView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel
    @Environment(Router.self) private var router

    init(viewModel: ForgotPasswordViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                Text("Enter your email and we'll send you a reset link.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.callout)
            }

            Button {
                Task { await viewModel.submit() }
            } label: {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Send Reset Link").frame(maxWidth: .infinity)
                }
            }
            .disabled(!viewModel.canSubmit)
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Check your email", isPresented: $viewModel.didSend) {
            Button("Back to sign in") { router.pop() }
        } message: {
            Text("If an account exists for \(viewModel.email), a reset link is on its way.")
        }
    }
}
