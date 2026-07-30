# AppTemplate — iOS App Template Design

**Date:** 2026-07-29
**Status:** Approved (design)

## Purpose

A reusable SwiftUI iOS app template that demonstrates a clean, testable
architecture: MVVM + Repository, manual dependency injection, token-based auth,
programmatic navigation, multi-environment configuration, and a local cache
abstraction that can be swapped for Core Data later. It boots into an Auth flow
or a Dashboard depending on whether a token is stored.

## Confirmed Decisions

| Area | Decision |
|------|----------|
| Deployment target | iOS 17.0 (app + test targets) |
| UI | SwiftUI, `NavigationStack`, programmatic navigation |
| Pattern | MVVM + Repository |
| Dependency Injection | Manual constructor injection via a composition root |
| Networking | Native `URLSession` + async/await behind an `APIClient` protocol |
| Testing | Swift Testing (`@Test` / `#expect`) |
| Backend | Public test API — dummyjson.com |
| Token storage | Keychain (protocol-backed) |
| Local cache | Protocol-backed `DiskCache` now; Core Data swappable later |
| Environments | xcconfig × 3 (Development / Staging / Production) |
| Bundle id | com.patrick.AppTemplate (existing) |
| Dev team | 3KG88YL8V2 (existing) |

## Architecture

```
App (composition root)
 ├─ AppDependencies   builds & wires everything once at launch
 └─ RootView          switches Auth <-> Dashboard on session state

Core
 ├─ Config      AppEnvironment (reads API_BASE_URL from Info.plist <- xcconfig)
 ├─ Network     APIClient (protocol) + LiveAPIClient, Endpoint, HTTPMethod, APIError
 │              AuthenticatedAPIClient (injects Bearer token per request)
 ├─ Storage     TokenStore (protocol) -> KeychainTokenStore + InMemoryTokenStore
 │              LocalCache (protocol) -> DiskCache (Codable -> JSON now)
 └─ Session     SessionManager (ObservableObject: .unauthenticated / .authenticated)

Features
 ├─ Auth        Login / Register / ForgotPassword (View + ViewModel each)
 └─ Dashboard   TabView -> Home tab + Profile tab, each with its own
                NavigationStack + Router

Data
 ├─ AuthRepository      login / register / forgotPassword
 └─ ProfileRepository   current user via token; Home product data
```

### Design principles

- Each unit has one clear purpose, communicates through a protocol, and is
  testable in isolation.
- ViewModels depend on repository **protocols**, never concrete types.
- Nothing constructs its own dependencies — everything arrives through `init`.

## Dependency Flow

`AppDependencies` is the single composition root. At launch it creates the
concrete implementations (`KeychainTokenStore`, `DiskCache`, `LiveAPIClient`,
`AuthenticatedAPIClient`, the repositories, and `SessionManager`) and hands
them to ViewModels through initializers. Tests and previews substitute mocks by
constructing ViewModels with fake dependencies.

## Session / Root Switch

- On launch `SessionManager` asks `TokenStore` for a saved token.
  - Token present -> state `.authenticated` -> `RootView` shows Dashboard.
  - No token -> state `.unauthenticated` -> `RootView` shows Auth.
- Login success stores the token in Keychain and sets `.authenticated`.
- Logout clears the token and sets `.unauthenticated`.
- `RootView` observes `SessionManager` and swaps the view tree accordingly.

## Navigation (programmatic, per-tab)

- Each tab owns a `Router` (`ObservableObject`) holding a `NavigationPath` and
  a nested `Route` enum.
- Views navigate by mutating the router: `router.push(.productDetail(id:))`,
  `router.pop()`, `router.popToRoot()`.
- No `NavigationLink(destination:)`. `navigationDestination(for:)` maps each
  `Route` case to its screen.
- The Auth flow has its own router (Login -> Register / ForgotPassword).
- Because tabs each hold an independent stack, switching tabs preserves each
  tab's navigation history.

## Environments (xcconfig)

- Three files: `Development.xcconfig`, `Staging.xcconfig`,
  `Production.xcconfig`, each defining `API_BASE_URL`.
- Three build configurations (Development / Staging / Production), each pointing
  at its xcconfig. Development/Staging are debug-style (no optimization);
  Production is release-style (optimized).
- Three schemes, one per configuration, so the environment is chosen by
  selecting a scheme.
- `API_BASE_URL` is surfaced via `Info.plist` and read at runtime by
  `AppEnvironment`.
- **xcconfig `//` caveat:** `//` starts a comment in xcconfig, so the scheme is
  stored split (e.g. `API_SCHEME = https` + `API_HOST = dummyjson.com`) or via
  the `$()` break trick; `AppEnvironment` reassembles the full URL.
- All three initially point at `https://dummyjson.com`.

## Local Cache (now) / Core Data (future)

- `LocalCache` protocol: `load<T: Codable>`, `save<T: Codable>`, `remove`,
  keyed by string.
- Ships as `DiskCache` (writes Codable JSON to the Caches directory).
- Repositories depend only on the protocol, so a future `CoreDataCache` slots in
  with no changes to Features or ViewModels.

## Networking

- `Endpoint` value type: path, method, query, body, whether auth is required.
- `APIClient` protocol: `func send<T: Decodable>(_ endpoint: Endpoint) async
  throws -> T`.
- `LiveAPIClient` implements it over `URLSession`.
- `AuthenticatedAPIClient` wraps an `APIClient` + `TokenStore` and injects the
  `Authorization: Bearer <token>` header when an endpoint requires auth.
- `APIError` enum: `invalidResponse`, `decoding`, `server(status, message)`,
  `unauthorized`, `transport(Error)`.

### dummyjson endpoints

| Feature | Endpoint |
|---------|----------|
| Login | `POST /auth/login` `{ username, password }` -> `accessToken` + user |
| Current user (token) | `GET /auth/me` with `Authorization: Bearer` |
| Home list | `GET /products` (sent through authenticated client) |
| Product detail | `GET /products/{id}` |
| Register | `POST /users/add` (simulated create) |
| Forgot password | No endpoint — simulated success in the repository |

Sample credentials: username `emilys`, password `emilyspass`.

## Features / Screens

### Auth
- **LoginView / LoginViewModel** — username + password, submit, error surface;
  on success stores token and flips session.
- **RegisterView / RegisterViewModel** — calls `/users/add`.
- **ForgotPasswordView / ForgotPasswordViewModel** — validates email, simulated
  success.

### Dashboard (TabView, two tabs)
- **Home tab** — products list from dummyjson; tap a product pushes
  `ProductDetailView` via the tab's router.
- **Profile tab** — current user from `/auth/me` (token-authenticated) + Logout
  button.

Two tabs are enough to prove the per-tab independent `NavigationStack` pattern.

## Testing (Swift Testing)

Unit-test target using `@Test` / `#expect`. Coverage:

- `LoginViewModel`: success flips session + stores token; failure surfaces error.
- `AuthRepository`: builds correct endpoint and decodes token, using a
  `MockAPIClient`.
- `TokenStore`: save / load / clear round-trip (`InMemoryTokenStore`).
- `DiskCache`: save / load / remove round-trip.
- `SessionManager`: launch with/without a stored token yields correct state.

Mocks (`MockAPIClient`, mock repositories) live in the test target and rely on
constructor injection.

## Previews

Every screen ships a `#Preview` wired with in-memory mocks (`InMemoryTokenStore`,
mock repositories returning canned data) so previews render instantly and never
hit the network.

## Project / Target Changes

- Set `IPHONEOS_DEPLOYMENT_TARGET = 17.0` on app and test targets.
- Add three build configurations + three xcconfig files + three schemes.
- Add a Swift Testing unit-test target.
- Replace the placeholder `ContentView` with `RootView`.
- Organize source into `App / Core / Features / Data` folders.

## Out of Scope (YAGNI)

- Refresh-token rotation / silent renewal (login stores the access token only).
- Real Core Data stack (only the protocol seam is provided now).
- Third tab / settings screen.
- Networking libraries, DI containers, biometric auth, offline sync.
