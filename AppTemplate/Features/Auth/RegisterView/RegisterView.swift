//
//  RegisterView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct RegisterView: View {
    @State private var viewModel: RegisterViewModel
    @Environment(Router.self) private var router

    init(viewModel: RegisterViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Your details") {
                TextField("First name", text: $viewModel.firstName)
                TextField("Last name", text: $viewModel.lastName)
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Credentials") {
                TextField("Username", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $viewModel.password)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.callout)
            }

            Button {
                Task { await viewModel.register() }
            } label: {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Create Account").frame(maxWidth: .infinity)
                }
            }
            .disabled(!viewModel.canSubmit)
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Account created", isPresented: $viewModel.didRegister) {
            Button("Back to sign in") { router.pop() }
        } message: {
            Text("Your account was created. You can now sign in.")
        }
    }
}
