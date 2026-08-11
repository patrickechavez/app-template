//
//  AppDependencies.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

@MainActor
final class AppDependencies {

    let session: SessionManager
    let deepLinks: DeepLinkParser

    private let auth: any AuthRepository
    private let users: any UserRepository
    private let items: any ItemRepository
    private let imageLoader: any ImageLoading
    private let tokenStore: any TokenStore
    private let events: SessionEventBus

    init(
        session: SessionManager,
        auth: any AuthRepository,
        users: any UserRepository,
        items: any ItemRepository,
        imageLoader: any ImageLoading,
        tokenStore: any TokenStore,
        events: SessionEventBus,
        deepLinks: DeepLinkParser
    ) {
        self.session = session
        self.auth = auth
        self.users = users
        self.items = items
        self.imageLoader = imageLoader
        self.tokenStore = tokenStore
        self.events = events
        self.deepLinks = deepLinks
    }

    static func live() -> AppDependencies {
        let events = SessionEventBus()
        let session = Self.urlSession()

        let tokenStore: any TokenStore = KeychainTokenStore()

        let metadata = MetadataInterceptor()
        let logging = LoggingInterceptor()

        let refreshClient = URLSessionAPIClient(
            session: session,
            interceptors: [metadata, logging],

            retryPolicy: .none
        )

        let coordinator = TokenRefreshCoordinator(
            store: tokenStore,
            refresher: LiveTokenRefresher(api: refreshClient),
            events: events
        )

        let api = URLSessionAPIClient(
            session: session,
            interceptors: [
                metadata,
                AuthInterceptor(coordinator: coordinator),
                SessionPolicyInterceptor(events: events),
                logging,
            ]
        )

        let users = LiveUserRepository(api: api)

        return AppDependencies(
            session: SessionManager(tokenStore: tokenStore, users: users, events: events),
            auth: LiveAuthRepository(api: api),
            users: users,
            items: LiveItemRepository(api: api),
            imageLoader: ImageLoader.shared,
            tokenStore: tokenStore,
            events: events,
            deepLinks: DeepLinkParser()
        )
    }

    private static func urlSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.timeout

        configuration.timeoutIntervalForResource = 300

        configuration.waitsForConnectivity = false

        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        let languages = Locale.preferredLanguages.prefix(3).joined(separator: ", ")
        configuration.httpAdditionalHeaders = ["Accept-Language": languages]
        return URLSession(configuration: configuration)
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(auth: auth, session: session)
    }

    func makeRegisterViewModel() -> RegisterViewModel {
        RegisterViewModel(auth: auth)
    }

    func makeForgotPasswordViewModel() -> ForgotPasswordViewModel {
        ForgotPasswordViewModel(auth: auth)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(repository: items)
    }

    func makeItemDetailViewModel(item: Item) -> ItemDetailViewModel {
        ItemDetailViewModel(item: item, repository: items)
    }

    func makeItemDetailViewModel(id: Int) -> ItemDetailViewModel {
        ItemDetailViewModel(itemID: id, repository: items)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            repository: users,
            auth: auth,
            session: session,
            tokenStore: tokenStore,
            imageLoader: imageLoader
        )
    }

    func makeHomeSheetViewModel() -> HomeSheetViewModel { HomeSheetViewModel() }
    func makeHomeCoverViewModel() -> HomeCoverViewModel { HomeCoverViewModel() }
}
