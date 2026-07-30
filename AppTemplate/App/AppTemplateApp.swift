//
//  AppTemplateApp.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

@main
struct AppTemplateApp: App {
    // The composition root, created once for the app's lifetime.
    @State private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
