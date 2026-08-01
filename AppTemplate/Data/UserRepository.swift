//
//  UserRepository.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import UIKit

protocol UserRepository {
    func currentUser() async throws -> User
    func uploadAvatar(_ image: UIImage, compression: ImageCompression) async throws -> User
}

extension UserRepository {
    // Convenience default preset.
    func uploadAvatar(_ image: UIImage) async throws -> User {
        try await uploadAvatar(image, compression: .profile)
    }
}

final class LiveUserRepository: UserRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func currentUser() async throws -> User {
        try await api.get(Endpoints.currentUser)
    }

    func uploadAvatar(_ image: UIImage, compression: ImageCompression) async throws -> User {
        try await uploadImage(image, fieldName: "avatar", to: Endpoints.avatar, compression: compression)
    }

    // Reusable upload pipeline: compress OFF the main thread, build the multipart
    // body, and upload. To support another image (cover, etc.), add a one-line
    // wrapper like `uploadAvatar` above with its own endpoint and preset.
    private func uploadImage(_ image: UIImage,
                             fieldName: String,
                             to path: String,
                             compression: ImageCompression) async throws -> User {
        let data = await Task.detached(priority: .userInitiated) {
            image.jpegData(for: compression)
        }.value
        guard let data else { throw APIError.invalidResponse }

        var form = MultipartFormData()
        form.addFile(fieldName, filename: "\(fieldName).jpg", mimeType: "image/jpeg", data: data)
        return try await api.upload(path, multipart: form)
    }
}
