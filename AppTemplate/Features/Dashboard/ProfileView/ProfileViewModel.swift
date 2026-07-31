//
//  ProfileViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import UIKit
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    private(set) var user: User?
    var isLoading = false
    var isUploadingAvatar = false
    var errorMessage: String?

    @ObservationIgnored private let repository: UserRepository
    @ObservationIgnored private let session: SessionManager
    @ObservationIgnored private let imageLoader: any ImageLoading

    init(repository: UserRepository, session: SessionManager, imageLoader: any ImageLoading) {
        self.repository = repository
        self.session = session
        self.imageLoader = imageLoader
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await repository.currentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadAvatar(_ image: UIImage) async {
        errorMessage = nil
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        let oldURL = user?.image.flatMap(URL.init)
        do {
            user = try await repository.uploadAvatar(image)
            // The new avatar may reuse the same URL — evict the stale cache entry.
            if let oldURL { await imageLoader.evict(oldURL) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        session.signOut()
    }
}
