//
//  RootView.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI

struct RootView: View {

    let dependencies: AppDependencies

    var body: some View {
        Group {
            switch dependencies.session.state {
            case .bootstrapping:
                LaunchView()

            case .unauthenticated:
                AuthFlowView(dependencies: dependencies)

                    .transition(.opacity)

            case .authenticated:
                DashboardView(dependencies: dependencies)
                    .transition(.opacity)
            }
        }
        .animation(Theme.Animation.standard, value: dependencies.session.state)
        .offlineBanner(dependencies.network)
        .task {
            await dependencies.session.bootstrap()
        }

        .fullScreenCover(item: serviceStatusBinding) { status in
            ServiceStatusView(status: status) {
                dependencies.session.dismissServiceStatus()
            }
        }
    }

    private var serviceStatusBinding: Binding<IdentifiedServiceStatus?> {
        Binding(
            get: { dependencies.session.serviceStatus.map(IdentifiedServiceStatus.init) },
            set: { if $0 == nil { dependencies.session.dismissServiceStatus() } }
        )
    }
}

struct IdentifiedServiceStatus: Identifiable {
    let value: SessionManager.ServiceStatus
    var id: String { String(describing: value) }

    init(_ value: SessionManager.ServiceStatus) {
        self.value = value
    }
}

struct LaunchView: View {
    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            ProgressView()
                .controlSize(.large)
                .testID(AccessibilityID.Shell.launchProgress)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Starting up", comment: "Accessibility label for the launch screen"))
    }
}

struct ServiceStatusView: View {

    let status: IdentifiedServiceStatus
    let onDismiss: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Theme.Color.accent)

            VStack(spacing: Theme.Spacing.md) {
                Text(title)
                    .font(Theme.Font.sectionTitle)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                if isUpdateRequired {
                    Button {
                        if let url = URL(string: "itms-apps://apple.com/app/id000000000") {
                            openURL(url)
                        }
                    } label: {
                        Text("Update Now", comment: "Button that opens the App Store listing")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {

                    Button {
                        onDismiss()
                    } label: {
                        Text("Try Again", comment: "Button that dismisses the maintenance screen")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .padding(Theme.Spacing.xxl)
        .interactiveDismissDisabled(isUpdateRequired)
        .testID(AccessibilityID.Shell.updateRequired)
    }

    private var isUpdateRequired: Bool {
        if case .updateRequired = status.value { return true }
        return false
    }

    private var icon: String {
        isUpdateRequired ? "arrow.down.circle.fill" : "wrench.and.screwdriver.fill"
    }

    private var title: LocalizedStringKey {
        isUpdateRequired ? "Update Required" : "Back Soon"
    }

    private var message: String {
        switch status.value {
        case let .updateRequired(message):
            message ?? String(
                localized: "This version of the app is no longer supported. Update to keep going.",
                comment: "Message shown when the app build is too old for the API"
            )
        case let .maintenance(message):
            message ?? String(
                localized: "We're doing some maintenance. Please try again in a few minutes.",
                comment: "Message shown when the backend is in maintenance mode"
            )
        }
    }
}
