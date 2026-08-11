//
//  Mocks.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

#if DEBUG

import Foundation
import UIKit

enum SampleData {

    static let user = User(
        id: 1,
        username: "raven",
        email: "raven@example.com",
        firstName: "Raven",
        lastName: "Solis",
        image: nil
    )

    static let tokens = AuthTokens(
        accessToken: "sample-access-token",
        refreshToken: "sample-refresh-token",
        expiresAt: Date().addingTimeInterval(3600)
    )

    static let items: [Item] = (1...12).map { index in
        Item(
            id: index,
            title: "Sample Item \(index)",
            description: "A description for sample item \(index). Long enough to wrap onto a second line.",
            price: Double(index) * 9.99,
            thumbnail: nil
        )
    }

    static func page(_ items: [Item] = Self.items, offset: Int = 0, total: Int? = nil) -> Page<Item> {
        Page(items: items, total: total ?? items.count, offset: offset, limit: 20)
    }
}

final class MockAuthRepository: AuthRepository, @unchecked Sendable {

    var loginResult: Result<AuthTokens, APIError> = .success(SampleData.tokens)
    var registerResult: Result<RegisterResponse, APIError> = .success(
        RegisterResponse(id: 1, username: "raven")
    )
    var passwordResetResult: Result<Void, APIError> = .success(())
    var logoutResult: Result<Void, APIError> = .success(())

    private(set) var loginCallCount = 0
    private(set) var lastLoginUsername: String?
    private(set) var logoutCallCount = 0

    init() {}

    func login(username: String, password: String) async throws -> AuthTokens {
        loginCallCount += 1
        lastLoginUsername = username
        return try loginResult.get()
    }

    func register(_ request: RegisterRequest) async throws -> RegisterResponse {
        try registerResult.get()
    }

    func requestPasswordReset(email: String) async throws {
        try passwordResetResult.get()
    }

    func resetPassword(token: String, newPassword: String) async throws {
        try passwordResetResult.get()
    }

    func logout(refreshToken: String?) async throws {
        logoutCallCount += 1
        try logoutResult.get()
    }
}

final class MockUserRepository: UserRepository, @unchecked Sendable {

    var currentUserResult: Result<User, APIError> = .success(SampleData.user)
    var uploadResult: Result<User, APIError> = .success(SampleData.user)

    private(set) var currentUserCallCount = 0
    private(set) var uploadCallCount = 0
    private(set) var registeredPushToken: String?

    init() {}

    func currentUser() async throws -> User {
        currentUserCallCount += 1
        return try currentUserResult.get()
    }

    func updateProfile(_ user: User) async throws -> User {
        user
    }

    func uploadAvatar(_ image: UIImage, compression: ImageCompression) async throws -> User {
        uploadCallCount += 1
        return try uploadResult.get()
    }

    func registerForPushNotifications(token: String) async throws {
        registeredPushToken = token
    }

    func unregisterForPushNotifications(token: String) async throws {
        registeredPushToken = nil
    }
}

final class MockItemRepository: ItemRepository, @unchecked Sendable {

    var pages: [Page<Item>] = [SampleData.page()]
    var error: APIError?

    var delay: Duration = .zero

    private(set) var requests: [PageRequest] = []

    init(items: [Item] = SampleData.items) {
        self.pages = [SampleData.page(items)]
    }

    func items(_ request: PageRequest) async throws -> Page<Item> {
        requests.append(request)

        if delay > .zero { try await Task.sleep(for: delay) }
        if let error { throw error }

        let index = requests.count - 1
        return pages.indices.contains(index) ? pages[index] : Page(items: [], total: 0, offset: request.offset)
    }

    func search(_ term: String, page: PageRequest) async throws -> Page<Item> {
        if let error { throw error }
        let matches = (pages.first?.items ?? []).filter {
            $0.title.localizedCaseInsensitiveContains(term)
        }
        return SampleData.page(matches)
    }

    func item(id: Int) async throws -> Item {
        if delay > .zero { try await Task.sleep(for: delay) }
        if let error { throw error }
        guard let item = pages.flatMap(\.items).first(where: { $0.id == id }) else {
            throw APIError.notFound()
        }
        return item
    }

    func create(_ draft: ItemDraft) async throws -> Item {
        if let error { throw error }
        return Item(id: 999, title: draft.title, description: draft.description, price: draft.price, thumbnail: nil)
    }

    func update(id: Int, draft: ItemDraft) async throws -> Item {
        if let error { throw error }
        return Item(id: id, title: draft.title, description: draft.description, price: draft.price, thumbnail: nil)
    }

    func delete(id: Int) async throws {
        if let error { throw error }
    }
}

actor MockImageLoader: ImageLoading {

    private(set) var evictedURLs: [URL] = []

    init() {}

    func image(for url: URL) async throws -> UIImage {
        throw ImageLoaderError.invalidImageData
    }

    func evict(_ url: URL) async {
        evictedURLs.append(url)
    }

    func clear() async {
        evictedURLs.removeAll()
    }

    func trimMemory() async {}
}

#endif
