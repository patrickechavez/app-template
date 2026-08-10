# AppTemplate

A production-ready SwiftUI app template: MVVM + Repository, Swift 6 strict
concurrency, a complete authentication lifecycle, and the shipping
infrastructure a real App Store release needs.

The goal is that starting project #2 is one command, and that nothing on the
"we'll fix it before launch" list is still outstanding on launch day.

- **iOS 17.0+** · **Swift 6** (strict concurrency, zero warnings) · **Xcode 26**
- No third-party dependencies.

---

## Quick start

```bash
./Scripts/bootstrap.sh --name MyApp --bundle-prefix com.acme --team ABCDE12345
```

Then point the app at your API:

```bash
open Config/Development.xcconfig   # and Staging / Production
```

Build and test:

```bash
xcodebuild test -project MyApp.xcodeproj -scheme Development -destination 'platform=iOS Simulator,name=iPhone 16'
```

Before you archive:

```bash
./Scripts/preflight.sh
```

---

## What's in the box

| Area | What you get |
|---|---|
| **Networking** | One `send` path, verb sugar on top. Typed error taxonomy, server error messages surfaced, interceptor chain, exponential backoff with jitter. |
| **Auth** | Access + refresh tokens, single-flight refresh, 401 → refresh → replay → sign out, proactive refresh before expiry. |
| **Storage** | Keychain-backed tokens with checked statuses, in-memory caching, per-environment isolation. |
| **Navigation** | Typed routes, deep links (custom scheme + universal links), push routing, deferred links, state restoration. |
| **UI** | `LoadState` for every screen, design system, empty/error/skeleton states, full localization, accessibility identifiers. |
| **Images** | Bounded memory and disk caches, LRU eviction, in-flight de-duplication. |
| **Observability** | `os.Logger` categories, analytics and crash-reporting seams (no vendor SDK). |
| **Testing** | 94 unit tests, 5 UI tests, a mock for every protocol, previews for every screen. |
| **Shipping** | Three environments, privacy manifest, SwiftLint + SwiftFormat, CI, preflight checks. |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  View            SwiftUI, no logic, no networking            │
│    ↕ @Observable                                             │
│  ViewModel       @MainActor, owns LoadState / ActionState    │
│    ↕ protocol                                                │
│  Repository      maps API responses to models                │
│    ↕ protocol                                                │
│  APIClient       one send path + interceptors                │
└─────────────────────────────────────────────────────────────┘
```

Each layer depends on the **protocol** of the layer below, never the concrete
type. `AppDependencies` is the only place the two meet, which is what makes
`AppDependencies.preview(_:)` able to swap the entire graph for mocks without a
single `#if DEBUG` in feature code.

### Concurrency

Default actor isolation is `nonisolated`. UI types (`ViewModel`, `Router`,
`AppNavigator`, `SessionManager`) are explicitly `@MainActor`; the networking
and data layers are not, so JSON decoding never runs on the main thread.
Shared mutable state lives in actors (`KeychainTokenStore`,
`TokenRefreshCoordinator`, `ImageLoader`).

> **Note on actors:** actors give mutual exclusion, not atomicity across
> `await`. `TokenRefreshCoordinator` documents where that distinction bites —
> it is the bug the single-flight test was written to catch.

---

## Adding a feature

Four files, in this order.

**1. Model** — `Models/Models.swift`

```swift
struct Invoice: Codable, Identifiable, Equatable, Sendable {
    let id: Int
    let total: Decimal
}
```

**2. Route** — `Core/Networking/APIRoute.swift`

```swift
enum Invoices {
    static let list = "invoices"
    static func detail(_ id: Int) -> String { "invoices/\(id)" }
}
```

**3. Repository** — `Data/InvoiceRepository.swift`

```swift
protocol InvoiceRepository: Sendable {
    func invoices(_ request: PageRequest) async throws -> Page<Invoice>
}

nonisolated struct LiveInvoiceRepository: InvoiceRepository {
    private let api: any APIClient
    init(api: any APIClient) { self.api = api }

    func invoices(_ request: PageRequest) async throws -> Page<Invoice> {
        try await api.get(APIRoute.Invoices.list, query: request.queryItems)
    }
}
```

**4. View model + view**

```swift
@Observable @MainActor
final class InvoiceListViewModel: LoadableViewModel {
    var state: LoadState<[Invoice]> = .idle
    @ObservationIgnored private let repository: any InvoiceRepository

    init(repository: any InvoiceRepository) { self.repository = repository }

    func load(isRefresh: Bool = false) async {
        await perform(isRefresh: isRefresh) { [repository] in
            try await repository.invoices(.first).items
        }
    }
}
```

```swift
struct InvoiceListView: View {
    @State private var viewModel: InvoiceListViewModel

    var body: some View {
        AsyncContentView(state: viewModel.state, retry: { await viewModel.load() }) { invoices in
            List(invoices) { InvoiceRow(invoice: $0) }
        }
        .task { if viewModel.state.needsLoad { await viewModel.load() } }
        .refreshable { await viewModel.load(isRefresh: true) }
    }
}
```

Then register a factory in `AppDependencies`. Loading, empty, error, retry,
cancellation, and offline handling all come from `AsyncContentView` and
`LoadableViewModel` — you don't write any of it.

---

## Environments

Three configurations, three xcconfigs, one shared base.

| | Development | Staging | Production |
|---|---|---|---|
| Bundle ID | `…​.dev` | `…​.staging` | *(none)* |
| Name | AppTemplate Dev | AppTemplate QA | App Template |
| Scheme | `apptemplate-dev://` | `apptemplate-staging://` | `apptemplate://` |
| Request logging | on | off | off |
| Retries | 0 | 2 | 2 |

All three install side by side on one device. Values live in
`Config/*.xcconfig` and reach code through `APIConfig` — never hardcode a URL,
and `preflight.sh` will tell you if you did.

**Secrets** belong in `Config/Secrets.xcconfig`, which is git-ignored. Add
`#include? "Secrets.xcconfig"` to the environment that needs it — the `?` makes
it optional so a fresh clone still builds.

---

## The auth lifecycle

The part most templates leave half-finished.

```
request → 401 ──→ refresh token available? ──no──→ clear tokens
                       │                              │
                      yes                    publish .expired
                       ↓                              │
              refresh (single-flight)                 ↓
                       │                        sign-in screen
              ┌────────┴────────┐
           success           failure
              │                 │
        replay request    clear tokens → .expired → sign-in screen
```

Three details that matter:

- **Single-flight.** Ten concurrent 401s produce **one** refresh. Backends that
  rotate refresh tokens would reject the other nine and sign the user out.
- **`requiresAuth: false`** on login, registration, and password reset. Without
  it, a wrong password (also a 401) triggers a refresh and signs out a user who
  was never signed in.
- **Offline at launch does not sign you out.** A failed token *verification* is
  treated as optimistic-continue; only an actual rejection ends the session.

---

## Testing

```bash
xcodebuild test -project AppTemplate.xcodeproj -scheme Development \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

| Suite | Covers |
|---|---|
| `NetworkingTests` | Status mapping, retries, error bodies, request building. Uses a stubbed `URLProtocol` — the real client is what's under test. |
| `AuthLifecycleTests` | Single-flight refresh, session invalidation, bootstrap paths. |
| `ViewModelTests` | Load states, pagination + de-duplication, sign in/out, validation. |
| `DecodingTests` | Pagination envelopes, error envelopes, dates. |
| `NavigationTests` | Deep-link parsing, routing, deferred links, restoration. |
| `AuthFlowUITests` | End-to-end auth screens, located by accessibility identifier. |

Mocks live in `Core/Testing/Mocks.swift` under `#if DEBUG`, shared by tests and
previews — one mock per protocol, so a protocol change breaks in one place.

> `NetworkingTests` is `.serialized`. `URLProtocol` stubs are necessarily
> static, and Swift Testing runs in parallel by default.

---

## Tooling

```bash
swiftlint                 # lint (CI runs --strict)
swiftformat .             # format
./Scripts/preflight.sh    # pre-archive safety checks
./Scripts/bootstrap.sh    # rename the template into a new project
```

`preflight.sh` fails the build on a placeholder production URL, request logging
enabled outside Development, a missing privacy manifest, `print()` in app
sources, hardcoded URLs, or a committed secrets file. It reports placeholders
as *warnings* while the project is still the un-bootstrapped template, so this
repo's own CI stays green — and as *errors* the moment you bootstrap.

---

## Before you ship

- [ ] `./Scripts/bootstrap.sh` — rename, then delete the script
- [ ] Real API URLs in all three xcconfigs
- [ ] Review `PrivacyInfo.xcprivacy` against what your backend actually stores
- [ ] Replace `Item` / `ItemRepository` with your first real resource
- [ ] Wire `AnalyticsTracking` and `CrashReporting` to your vendors
- [ ] Replace the App Store URL in `ServiceStatusView`
- [ ] Set your universal-link hosts in `DeepLinkParser` + Associated Domains
- [ ] Finish `ResetPasswordView` (marked `TODO: [TEMPLATE]`)
- [ ] App icon and accent colour
- [ ] `./Scripts/preflight.sh` passes with zero failures

---

## Layout

```
AppTemplate/
├── App/              entry point, composition root, root view
├── Components/       reusable inputs, buttons, avatar, picker
├── Core/
│   ├── Images/       bounded two-tier image cache
│   ├── Navigation/   typed routes, deep links, routers
│   ├── Networking/   client, endpoints, errors, interceptors
│   ├── Observability/ logging, analytics + crash seams
│   ├── Session/      tokens, refresh coordination, session state
│   ├── Storage/      Keychain
│   ├── Testing/      mocks, preview host (DEBUG only)
│   └── UI/           LoadState, AsyncContentView, view-model helpers
├── Data/             repositories
├── DesignSystem/     theme, accessibility identifiers
├── Features/         one folder per screen (View + ViewModel)
├── Models/           models, pagination
└── Resources/        String Catalog
```
