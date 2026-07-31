//
//  Models.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

// MARK: - Auth

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct AuthResponse: Decodable {
    let accessToken: String
}

struct RegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let username: String
    let password: String
}

struct RegisterResponse: Decodable {
    let id: Int
    let username: String
}

struct User: Decodable, Identifiable, Equatable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let image: String?

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - Items (sample feature — replace with your own models)

struct Item: Decodable, Identifiable, Equatable, Hashable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let thumbnail: String?
}

struct ItemListResponse: Decodable {
    let items: [Item]

    enum CodingKeys: String, CodingKey {
        case items = "products"
    }
}
