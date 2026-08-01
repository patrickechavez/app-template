//
//  ProfileView.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @State private var pickedImage: UIImage?
    @Environment(Router.self) private var router

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            if let user = viewModel.user {
                Section {
                    HStack(spacing: 16) {
                        CachedAsyncImage(url: user.image.flatMap(URL.init)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text(user.fullName).font(.headline)
                            Text(user.email).font(.callout).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    ImagePicker(image: $pickedImage) {
                        Label("Change Photo", systemImage: "photo")
                    }
                    .disabled(viewModel.isUploadingAvatar)

                    if viewModel.isUploadingAvatar {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Uploading…").foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Account") {
                    LabeledContent("Username", value: user.username)
                    LabeledContent("User ID", value: String(user.id))
                }
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView("Couldn't load profile",
                                       systemImage: "person.crop.circle.badge.exclamationmark",
                                       description: Text(errorMessage))
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    router.present(alert: .confirmDestructive(
                        "Sign Out?",
                        confirm: "Sign Out",
                        onConfirm: { viewModel.signOut() }
                    ))
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.user == nil {
                ProgressView()
            }
        }
        .navigationTitle("Profile")
        .task { await viewModel.load() }
        .onChange(of: pickedImage) { _, image in
            if let image {
                Task { await viewModel.uploadAvatar(image) }
            }
        }
    }
}
