//
//  APIRoute.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum APIRoute {

    enum Auth {
        static let login = "auth/login"
        static let register = "users/add"
        static let refresh = "auth/refresh"
        static let logout = "auth/logout"
        static let currentUser = "auth/me"
        static let requestPasswordReset = "auth/forgot-password"
        static let resetPassword = "auth/reset-password"
    }

    enum Users {
        static let avatar = "user/avatar"
        static func profile(_ id: Int) -> String { "users/\(id)" }
    }

    enum System {

        static let versionCheck = "system/version"
    }

    enum Devices {

        static let register = "devices"
        static func unregister(_ token: String) -> String { "devices/\(token)" }
    }

    enum Items {
        static let list = "products"
        static let search = "products/search"
        static func detail(_ id: Int) -> String { "products/\(id)" }
    }
}
