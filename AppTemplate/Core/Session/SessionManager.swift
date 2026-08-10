//
//  SessionManager.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Observation
import os

@Observable
@MainActor
final class SessionManager {

    enum State: Equatable {

        case bootstrapping
        case unauthenticated
        case authenticated
    }

    private(set) var state: State = .bootstrapping

    private(set) var currentUser: User?

    private(set) var serviceStatus: ServiceStatus?

    enum ServiceStatus: Equatable {
        case updateRequired(message: String?)
        case maintenance(message: String?)
    }

    @ObservationIgnored private let tokenStore: any TokenStore
    @ObservationIgnored private let users: any UserRepository
    @ObservationIgnored private let events: SessionEventBus
    @ObservationIgnored private var eventTask: Task<Void, Never>?

    init(tokenStore: any TokenStore, users: any UserRepository, events: SessionEventBus) {
        self.tokenStore = tokenStore
        self.users = users
        self.events = events
        observeEvents()
    }

    deinit {
        eventTask?.cancel()
    }

    func bootstrap() async {
        guard await tokenStore.load() != nil else {
            state = .unauthenticated
            return
        }

        do {
            currentUser = try await users.currentUser()
            state = .authenticated
            AppLogger.lifecycle.notice("Resumed existing session")
        } catch let error as APIError where error.invalidatesSession {

            await signOut()
        } catch {

            AppLogger.lifecycle.notice(
                "Could not verify session (\(error.localizedDescription, privacy: .public)); continuing optimistically."
            )
            state = .authenticated
        }
    }

    func didAuthenticate(tokens: AuthTokens, user: User? = nil) async {
        do {
            try await tokenStore.save(tokens)
        } catch {

            AppLogger.auth.error("Could not persist tokens: \(error.localizedDescription, privacy: .public)")
        }

        currentUser = user
        state = .authenticated

        if user == nil {

            Task { await refreshCurrentUser() }
        }
    }

    func signOut() async {
        await tokenStore.clear()
        currentUser = nil
        state = .unauthenticated
        AppLogger.lifecycle.notice("Signed out")
    }

    func refreshCurrentUser() async {
        guard state == .authenticated else { return }
        currentUser = try? await users.currentUser()
    }

    func update(user: User) {
        currentUser = user
    }

    func dismissServiceStatus() {
        serviceStatus = nil
    }

    private func observeEvents() {
        eventTask = Task { [weak self, events] in
            for await event in events.events {
                guard let self else { return }
                await self.handle(event)
            }
        }
    }

    private func handle(_ event: SessionEvent) async {
        switch event {
        case .expired:

            guard state == .authenticated else { return }
            AppLogger.auth.notice("Session expired — returning to sign-in")
            await signOut()

        case let .updateRequired(message):
            serviceStatus = .updateRequired(message: message)

        case let .maintenance(message):
            serviceStatus = .maintenance(message: message)
        }
    }
}
