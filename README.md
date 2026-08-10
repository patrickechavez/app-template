# AppTemplate

A production-ready SwiftUI app template. MVVM + Repository, Swift 6 strict concurrency, a complete auth lifecycle, and no third-party dependencies.

- iOS 17+ · Swift 6 · Xcode 26

## Getting started

1. Point the app at your API in `Config/Development.xcconfig` (and Staging / Production).
2. Rename the project — set `APP_NAME` and `APP_BUNDLE_PREFIX` in `Config/Shared.xcconfig`.
3. Build and run.

```bash
xcodebuild -scheme Development -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## What's inside

- **Networking** — one send path with verb helpers, typed errors, server-message parsing, interceptors, retry with backoff
- **Auth** — access + refresh tokens, single-flight refresh, 401 to refresh to retry to sign-out, Keychain storage
- **Navigation** — typed routes, deep links, universal links, deferred links, force-update gate
- **UI** — design system, unified `LoadState`, empty / error / skeleton states, accessibility identifiers, localization via String Catalog
- **Images** — bounded two-tier cache with LRU eviction and in-flight de-duplication
- **Build** — three environments, privacy manifest, SwiftLint + SwiftFormat, CI

## Architecture

```
View (SwiftUI, no logic)
  ↕ @Observable
ViewModel (@MainActor, owns LoadState)
  ↕ protocol
Repository (maps API to models)
  ↕ protocol
APIClient (one send path + interceptors)
```

Each layer depends on the protocol below it. `AppDependencies` is the one place concrete types meet, which is what makes it testable and swappable.

## Environments

Three configs, one shared base. All install side by side on one device.

| | Development | Staging | Production |
|---|---|---|---|
| Bundle ID | `.dev` | `.staging` | *(none)* |
| Request logging | on | off | off |

Values live in `Config/*.xcconfig` and reach code through `APIConfig`. Never hardcode a URL.

## Structure

```
AppTemplate/
├── App/              entry point, composition root
├── Components/       reusable inputs, buttons, picker
├── Core/
│   ├── Images/       two-tier image cache
│   ├── Navigation/   typed routes, deep links
│   ├── Networking/   client, endpoints, errors, interceptors
│   ├── Session/      tokens, refresh, session state
│   └── UI/           LoadState, AsyncContentView
├── Data/             repositories
├── DesignSystem/     theme, accessibility identifiers
├── Features/         one folder per screen
├── Models/           models, pagination
└── Resources/        String Catalog
```

## Before you ship

- Real API URLs in all three xcconfigs
- Review `PrivacyInfo.xcprivacy` against what your backend stores
- Replace the `Item` sample with your first real resource
- App icon and accent color
