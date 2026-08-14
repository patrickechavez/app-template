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
- **Build** — three environments, privacy manifest

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

## Secrets

Client SDK keys you'd rather not publish go in `Config/Secrets.xcconfig`, which is gitignored. Copy `Secrets.example.xcconfig`, drop the `.example`, fill it in — all three environments already `#include?` it, and the `?` means a clone without the file still builds.

Everything there is substituted into Info.plist and ships inside the IPA. It keeps values out of git, not off a device. Server-side keys belong on your server.

## Firebase

Crashlytics, Analytics, and Messaging via SPM. `GoogleService-Info.plist` is gitignored — supply your own.

1. Create three Firebase projects, one per environment.
2. Register an iOS app in each using that environment's bundle ID.
3. Download each `GoogleService-Info.plist` into its matching folder, creating the folders as you go.

```
AppTemplate/Firebase/
├── Development/GoogleService-Info.plist
├── Staging/GoogleService-Info.plist
└── Production/GoogleService-Info.plist
```

The folders are absent from git because they hold nothing but ignored files.

Leave **Target Membership unchecked** on every plist. The `Copy GoogleService-Info.plist` build phase picks the right one from `$CONFIGURATION` and fails the build if its `BUNDLE_ID` doesn't match. Checking membership makes Xcode copy it too, and the build stops with `Multiple commands produce`.

For push, add the Push Notifications capability and upload an APNs `.p8` key to each Firebase project.

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
├── Firebase/         one GoogleService-Info.plist per environment
├── DesignSystem/     theme, accessibility identifiers
├── Features/         one folder per screen
├── Models/           models, pagination
└── Resources/        String Catalog
```

## Before you ship

- Real API URLs in all three xcconfigs
- All three `GoogleService-Info.plist` files in place
- Review `PrivacyInfo.xcprivacy` against what your backend stores
- Replace the `Item` sample with your first real resource
- App icon and accent color
