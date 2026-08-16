//
//  AppTemplateApp.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import UIKit
import os
import FirebaseCore
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        return true
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        AppLogger.lifecycle.debug("FCM token \(fcmToken ?? "nil")")
    }
}

@main
struct AppTemplateApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var dependencies = AppDependencies.live()
    @State private var navigator: AppNavigator

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let dependencies = AppDependencies.live()
        _dependencies = State(wrappedValue: dependencies)
        _navigator = State(
            wrappedValue: AppNavigator(parser: dependencies.deepLinks)
        )
        reportDeviceSecurity(dependencies: dependencies)
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environment(navigator)
                .overlay {
                    if scenePhase != .active {
                        PrivacyShieldView()
                    }
                }

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
                .onReceive(ScreenshotDetector.publisher) { _ in
                    dependencies.analytics.track("screenshot_captured")
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

    /// Report-only hardening checks: flag the device in analytics and logs if
    /// jailbreak indicators or a debugger are detected, without blocking.
    private func reportDeviceSecurity(dependencies: AppDependencies) {
        if DefaultJailbreakDetector().isJailbroken {
            dependencies.analytics.track("device_jailbroken")
            AppLogger.lifecycle.warning("Jailbreak indicators detected on device")
        }

        if DefaultDebuggerDetector().isDebuggerAttached {
            dependencies.analytics.track("debugger_attached")
            AppLogger.lifecycle.warning("Debugger is attached to the process")
        }
    }
}
