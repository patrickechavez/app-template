//
//  AppRoute.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

protocol AppRoute: Hashable, Codable, Sendable {}

enum AppTab: String, Hashable, Codable, CaseIterable, Identifiable, Sendable {
    case home
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: String(localized: "Items", comment: "Home tab title")
        case .profile: String(localized: "Profile", comment: "Profile tab title")
        }
    }

    var systemImage: String {
        switch self {
        case .home: "square.grid.2x2"
        case .profile: "person.crop.circle"
        }
    }
}

enum AuthRoute: AppRoute {
    case register
    case forgotPassword
    case resetPassword(token: String)
}

enum HomeRoute: AppRoute {
    case itemDetail(id: Int)
}

enum ProfileRoute: AppRoute {
    case editProfile
    case settings
}
