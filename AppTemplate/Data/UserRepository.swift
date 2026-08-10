//
//  UserRepository.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import UIKit

protocol UserRepository: Sendable {
    func currentUser() async throws -> User
    func updateProfile(_ user: User) async throws -> User
    func uploadAvatar(_ image: UIImage, compression: ImageCompression) async throws -> User
    func registerForPushNotifications(token: String) async throws
    func unregisterForPushNotifications(token: String) async throws
}

extension UserRepository {

    func uploadAvatar(_ image: UIImage) async throws -> User {
        try await uploadAvatar(image, compression: .profile)
    }
}

nonisolated struct LiveUserRepository: UserRepository {

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func currentUser() async throws -> User {
        try await api.get(APIRoute.Auth.currentUser)
    }

    func updateProfile(_ user: User) async throws -> User {
        try await api.patch(APIRoute.Users.profile(user.id), body: user)
    }

    func uploadAvatar(_ image: UIImage, compression: ImageCompression) async throws -> User {
        try await upload(image, fieldName: "avatar", to: APIRoute.Users.avatar, compression: compression)
    }

    func registerForPushNotifications(token: String) async throws {
        try await api.post(APIRoute.Devices.register, body: DeviceRegistration(pushToken: token))
    }

    func unregisterForPushNotifications(token: String) async throws {
        try await api.delete(APIRoute.Devices.unregister(token))
    }

    private func upload(
        _ image: UIImage,
        fieldName: String,
        to path: String,
        compression: ImageCompression
    ) async throws -> User {

        let data = await Task.detached(priority: .userInitiated) {
            image.jpegData(for: compression)
        }.value

        guard let data else {
            throw APIError.invalidResponse
        }

        var form = MultipartFormData()
        form.addFile(fieldName, filename: "\(fieldName).jpg", mimeType: "image/jpeg", data: data)

        return try await api.upload(path, form: form)
    }
}
