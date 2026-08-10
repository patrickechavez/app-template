//
//  HTTPMethod.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum HTTPMethod: String, Sendable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete: true
        case .post, .patch: false
        }
    }
}
