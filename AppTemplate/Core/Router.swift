//
//  Router.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class Router {
    var path = NavigationPath()

    func push<Route: Hashable>(_ route: Route) { path.append(route) }
    func pop() { if !path.isEmpty { path.removeLast() } }
    func popToRoot() { path.removeLast(path.count) }
}
