//
//  AppTemplateApp.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import os

@main
struct AppTemplateApp: App {

    @State private var dependencies = AppDependencies.live()
    @State private var navigator: AppNavigator

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let dependencies = AppDependencies.live()
        _dependencies = State(wrappedValue: dependencies)
        _navigator = State(
            wrappedValue: AppNavigator(parser: dependencies.deepLinks)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environment(navigator)

                .onOpenURL { url in
                    navigator.open(url, isAuthenticated: dependencies.session.state == .authenticated)
                }

                .onChange(of: dependencies.session.state) { _, state in
                    switch state {
                    case .authenticated:
                        navigator.resumePendingLink()
                    case .unauthenticated:
                        navigator.reset()
                    case .bootstrapping:
                        break
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    handle(phase)
                }
        }
    }

    private func handle(_ phase: ScenePhase) {
        switch phase {
        case .active:
            AppLogger.lifecycle.debug("Scene active")
        case .background:
            AppLogger.lifecycle.debug("Scene backgrounded")

            Task { await ImageLoader.shared.trimMemory() }
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}
