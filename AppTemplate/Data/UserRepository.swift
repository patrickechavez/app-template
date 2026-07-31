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
    func uploadAvatar(_ image: UIImage) async throws -> User
}

final class LiveUserRepository: UserRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func currentUser() async throws -> User {
        try await api.get(Endpoints.currentUser)
    }

    func uploadAvatar(_ image: UIImage) async throws -> User {
        var form = MultipartFormData()
        form.addImage(image, name: "avatar", filename: "avatar.jpg")
        return try await api.upload(Endpoints.avatar, multipart: form)
    }
}
