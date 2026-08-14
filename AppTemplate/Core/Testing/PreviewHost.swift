//
//  PreviewHost.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

#if DEBUG

import SwiftUI

enum PreviewScenario: Sendable {
    case loaded
    case empty
    case loading
    case failure(APIError)
}

struct PreviewHost<Content: View>: View {

    let scenario: PreviewScenario
    @ViewBuilder let content: (AppDependencies) -> Content

    @State private var dependencies: AppDependencies
    @State private var navigator = AppNavigator()

    init(scenario: PreviewScenario = .loaded, @ViewBuilder content: @escaping (AppDependencies) -> Content) {
        self.scenario = scenario
        self.content = content
        _dependencies = State(wrappedValue: AppDependencies.preview(scenario))
    }

    var body: some View {
        content(dependencies)
            .environment(navigator)
    }
}

extension AppDependencies {

    static func preview(_ scenario: PreviewScenario = .loaded) -> AppDependencies {
        let events = SessionEventBus()
        let tokenStore = InMemoryTokenStore(tokens: SampleData.tokens)

        let auth = MockAuthRepository()
        let users = MockUserRepository()
        let items = MockItemRepository()

        switch scenario {
        case .loaded:
            break

        case .empty:
            items.pages = [Page(items: [], total: 0, offset: 0, limit: 20)]

        case .loading:

            items.delay = .seconds(60)

        case let .failure(error):
            items.error = error
            auth.loginResult = .failure(error)
            users.currentUserResult = .failure(error)
        }

        let session = SessionManager(tokenStore: tokenStore, users: users, events: events)

        return AppDependencies(
            session: session,
            auth: auth,
            users: users,
            items: items,
            imageLoader: MockImageLoader(),
            tokenStore: tokenStore,
            events: events,
            deepLinks: DeepLinkParser(),
            analytics: NoopAnalyticsTracker(),
            crashes: NoopCrashReporter()
        )
    }
}

#endif
