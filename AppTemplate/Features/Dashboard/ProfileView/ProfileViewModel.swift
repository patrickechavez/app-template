//
//  ProfileViewModel.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    private(set) var user: User?
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let repository: UserRepository
    @ObservationIgnored private let session: SessionManager

    init(repository: UserRepository, session: SessionManager) {
        self.repository = repository
        self.session = session
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

    func signOut() {
        session.signOut()
    }
}
