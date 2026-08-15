# AppTemplate

A production-ready SwiftUI app template. MVVM + Repository, Swift 6 strict concurrency, a complete auth lifecycle, and no third-party dependencies.

- iOS 17+ · Swift 6 · Xcode 26

## Getting started

Clone, rename, and you have a running app in under ten minutes.

```bash
git clone <this-repo> <AppName> && cd <AppName>
Scripts/rename.sh <AppName> <BundlePrefix> [DisplayName]
```

| | | |
|---|---|---|
| `<AppName>` | required | Becomes the target, the source folder, and a Swift type. Letters and digits, starting with a letter — no spaces or hyphens. e.g. `Gastos` |
| `<BundlePrefix>` | required | Lowercase reverse-DNS with at least two components. e.g. `com.acmecorp` |
| `[DisplayName]` | optional | The home screen name. Defaults to `<AppName>`, so you only pass it when the two differ. e.g. `"Gas Tos"` |

```bash
Scripts/rename.sh Gastos com.patrick
Scripts/rename.sh MyApp com.acmecorp "My App"
```

The script renames the project, target, schemes, source folder, app entry point, and every file header, and rewrites the bundle IDs, display names, and deep link scheme. It requires a clean working tree, so `git checkout . && git clean -fd` undoes any run.

Start your own history when you're happy:

```bash
rm -rf .git && git init && git add -A && git commit -m "Initial commit"
```

Then three things the script can't do for you.

1. **Your API** — set `API_BASE_URL` in each of the three `Config/*.xcconfig`.
2. **Firebase** — create a project and download its `GoogleService-Info.plist` (see below).
3. **App icon** — `Assets.xcassets/AppIcon.appiconset` ships empty.

```bash
xcodebuild -scheme Development -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Removing the sample

`Item` is a worked example, not something to build on. Keep it while you write your first real feature — it's the only place pagination, `LoadState`, and the repository pattern are shown working end to end — then delete it.

```
Features/Dashboard/HomeView/          the list screen
Features/Dashboard/ItemDetailView/    the detail screen
Data/ItemRepository.swift
Models/Models.swift                   the Item and ItemDraft types
Core/Testing/Mocks.swift              SampleData.items and MockItemRepository
```

Then remove `makeHomeViewModel`, `makeItemDetailViewModel` (both overloads), and the `items` property from `AppDependencies`, and drop `.itemDetail` from `HomeRoute`. The compiler finds anything you miss.

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
3. Download each `GoogleService-Info.plist` into its matching folder, creating the folders as you go. Development is enough to start — the Staging and Production schemes fail with `Missing Firebase plist` until you add theirs, which is the guard working rather than a broken checkout.

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
- The `Item` sample removed
- Review `PrivacyInfo.xcprivacy` against what your backend stores
- App icon and accent color
