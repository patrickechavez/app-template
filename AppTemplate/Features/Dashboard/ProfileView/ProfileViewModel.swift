//
//  ProfileViewModel.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation
import UIKit
import os

@Observable
@MainActor
final class ProfileViewModel: LoadableViewModel {

    var state: LoadState<User> = .idle

    let avatarUpload = ActionState()

    @ObservationIgnored private let repository: any UserRepository
    @ObservationIgnored private let auth: any AuthRepository
    @ObservationIgnored private let session: SessionManager
    @ObservationIgnored private let tokenStore: any TokenStore
    @ObservationIgnored private let imageLoader: any ImageLoading

    init(
        repository: any UserRepository,
        auth: any AuthRepository,
        session: SessionManager,
        tokenStore: any TokenStore,
        imageLoader: any ImageLoading
    ) {
        self.repository = repository
        self.auth = auth
        self.session = session
        self.tokenStore = tokenStore
        self.imageLoader = imageLoader

        if let user = session.currentUser {
            state = .loaded(user)
        }
    }

    func load(isRefresh: Bool = false) async {
        await perform(isRefresh: isRefresh || state.value != nil) { [repository] in
            try await repository.currentUser()
        }
        if let user = state.value {
            session.update(user: user)
        }
    }

    func uploadAvatar(_ image: UIImage) async {
        let previousAvatarURL = state.value?.avatarURL

        let updated = await avatarUpload.run { [repository] in
            try await repository.uploadAvatar(image)
        }
        guard let updated else { return }

        if let previousAvatarURL {
            await imageLoader.evict(previousAvatarURL)
        }

        state = .loaded(updated)
        session.update(user: updated)
    }

    func signOut() async {
        let refreshToken = await tokenStore.load()?.refreshToken

        do {
            try await auth.logout(refreshToken: refreshToken)
        } catch {
            AppLogger.auth.notice(
                "Server-side logout failed (\(error.localizedDescription, privacy: .public)); clearing locally anyway."
            )
        }

        await session.signOut()
    }
}
