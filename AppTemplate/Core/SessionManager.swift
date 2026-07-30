//
//  SessionManager.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class SessionManager {
    enum State: Equatable {
        case unauthenticated
        case authenticated
    }

    private(set) var state: State

    @ObservationIgnored private let tokenStore: TokenStore

    init(tokenStore: TokenStore) {
        self.tokenStore = tokenStore
        // Decide the initial screen from whether a token was previously stored.
        state = tokenStore.token == nil ? .unauthenticated : .authenticated
    }

    func didAuthenticate(token: String) {
        tokenStore.save(token)
        state = .authenticated
    }

    func signOut() {
        tokenStore.clear()
        state = .unauthenticated
    }
}
