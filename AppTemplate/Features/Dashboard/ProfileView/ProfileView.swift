//
//  ProfileView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import UIKit

struct ProfileView: View {

    @State private var viewModel: ProfileViewModel
    @State private var pickedImage: UIImage?

    @Environment(Router<ProfileRoute>.self) private var router

    init(viewModel: ProfileViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        AsyncContentView(
            state: viewModel.state,
            emptyTitle: "Profile unavailable",
            emptyIcon: "person.crop.circle.badge.exclamationmark",
            retry: { await viewModel.load() }
        ) { user in
            profile(user)
        }
        .navigationTitle(Text("Profile", comment: "Title of the profile screen"))
        .task {
            guard viewModel.state.needsLoad else { return }
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(isRefresh: true)
        }
        .onChange(of: pickedImage) { _, image in
            guard let image else { return }
            Task {
                await viewModel.uploadAvatar(image)

                pickedImage = nil
            }
        }
    }

    private func profile(_ user: User) -> some View {
        List {
            headerSection(user)
            accountSection(user)
            settingsSection
            signOutSection
        }
    }

    private func headerSection(_ user: User) -> some View {
        Section {
            HStack(spacing: Theme.Spacing.lg) {
                AvatarView(user: user, size: Theme.Size.avatarMedium)
                    .testID(AccessibilityID.Profile.avatar)
                    .overlay {
                        if viewModel.avatarUpload.isRunning {
                            Circle()
                                .fill(.black.opacity(0.4))
                                .overlay { ProgressView().tint(.white) }
                        }
                    }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(user.fullName)
                        .font(Theme.Font.cardTitle)
                        .testID(AccessibilityID.Profile.fullName)

                    Text(user.email)
                        .font(Theme.Font.secondary)
                        .foregroundStyle(Theme.Color.secondaryText)
                        .testID(AccessibilityID.Profile.email)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
            .accessibilityElement(children: .combine)

            ImagePicker(image: $pickedImage) {
                Label {
                    Text("Change Photo", comment: "Button that opens the photo picker")
                } icon: {
                    Image(systemName: "photo")
                }
            }
            .disabled(viewModel.avatarUpload.isRunning)
            .testID(AccessibilityID.Profile.changePhotoButton)

            if let error = viewModel.avatarUpload.errorMessage {
                InlineErrorText(error)
            }
        }
    }

    private func accountSection(_ user: User) -> some View {
        Section {
            LabeledContent {
                Text(user.username)
            } label: {
                Text("Username", comment: "Label for the username row on the profile screen")
            }

            LabeledContent {

                Text(user.id, format: .number.grouping(.never))
            } label: {
                Text("User ID", comment: "Label for the user ID row on the profile screen")
            }
        } header: {
            Text("Account", comment: "Header of the account section on the profile screen")
        }
    }

    private var settingsSection: some View {
        Section {
            Button {
                router.push(.settings)
            } label: {
                Label {
                    Text("Settings", comment: "Button that opens the settings screen")
                } icon: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                router.present(alert: .confirmDestructive(
                    String(
                        localized: "Sign out of your account?",
                        comment: "Title of the sign-out confirmation alert"
                    ),
                    message: String(
                        localized: "You'll need to sign in again to use the app.",
                        comment: "Message of the sign-out confirmation alert"
                    ),
                    confirm: String(localized: "Sign Out", comment: "Confirm button of the sign-out alert"),
                    onConfirm: {
                        Task { await viewModel.signOut() }
                    }
                ))
            } label: {
                Text("Sign Out", comment: "Button that signs the user out")
            }
            .testID(AccessibilityID.Profile.signOutButton)
        }
    }
}

#if DEBUG

#Preview {
    PreviewHost { dependencies in
        NavigationStack {
            ProfileView(viewModel: dependencies.makeProfileViewModel())
        }
        .environment(Router<ProfileRoute>())
    }
}

#endif
