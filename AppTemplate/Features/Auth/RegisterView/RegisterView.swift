//
//  RegisterView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import UIKit

struct RegisterView: View {
    @State private var viewModel: RegisterViewModel
    @Environment(Router.self) private var router

    init(viewModel: RegisterViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                avatarPicker

                AppTextField(text: $viewModel.firstName, label: "First name",
                             capitalization: .words, contentType: .givenName)
                AppTextField(text: $viewModel.lastName, label: "Last name",
                             capitalization: .words, contentType: .familyName)
                EmailField(text: $viewModel.email)
                UsernameField(text: $viewModel.username, placeholder: "Choose a username")
                PasswordField(text: $viewModel.password, contentType: .newPassword)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit)
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Account created", isPresented: $viewModel.didRegister) {
            Button("Back to sign in") { router.pop() }
        } message: {
            Text("Your account was created. You can now sign in.")
        }
    }

    private var avatarPicker: some View {
        ImagePicker(image: $viewModel.selectedImage) {
            ZStack {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle().fill(Color.secondary.opacity(0.15))
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }
}
