//
//  Endpoints.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum Endpoints {
    // Auth
    static let login = "auth/login"
    static let register = "users/add"
    static let currentUser = "auth/me"
    static let avatar = "user/avatar"

    // Items (sample feature — replace with your own resource paths)
    static let items = "products"
    static func item(_ id: Int) -> String { "products/\(id)" }
}
