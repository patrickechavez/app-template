# AppTemplate

A production-ready SwiftUI app template. MVVM + Repository, Swift 6 strict concurrency, a complete auth lifecycle, and one third-party dependency — Firebase, kept behind protocol seams so the rest of the app never touches it.

- iOS 17+ · Swift 6 · Xcode 26

## Getting started

Clone, rename, and you have a running app in under ten minutes.

### 1. Clone and rename

Three commands. Substitute your own values.

```bash
git clone <this-repo> MyApp
cd MyApp
Scripts/rename.sh MyApp com.acmecorp "My App"
```

The three arguments to the script:

| | | |
|---|---|---|
| `MyApp` | required | The app name. Becomes the target, the source folder, and a Swift type, so it takes letters and digits only, starting with a letter — no spaces or hyphens. |
| `com.acmecorp` | required | Your bundle prefix. Lowercase reverse-DNS, at least two components. |
| `"My App"` | optional | The home screen name, quoted because it can contain spaces. Leave it off when it matches the app name — `Scripts/rename.sh Runly com.acmecorp` gives an app called Runly. |

This renames the project, target, schemes, source folder, app entry point, and every file header, and rewrites the bundle IDs, display names, and deep link scheme. It needs a clean working tree, so `git checkout . && git clean -fd` undoes any run.

### 2. Start your own history

```bash
rm -rf .git && git init && git add -A && git commit -m "Initial commit"
```

### 3. Finish the setup

Three things the script can't do for you.

- **Your API** — set `API_BASE_URL` in each of the three `Config/*.xcconfig`
- **Firebase** — create a project and download its `GoogleService-Info.plist` (see below)
- **App icon** — `Assets.xcassets/AppIcon.appiconset` ships empty

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
- **Navigation** — typed routes, deep links, universal links, deferred links, force-update and maintenance gates
- **UI** — design system, unified `LoadState`, empty / error / skeleton states, accessibility identifiers, localization via String Catalog
- **Images** — bounded two-tier cache with LRU eviction and in-flight de-duplication
- **Connectivity** — `NWPathMonitor` behind an offline banner, so a failing screen reads as a connection problem
- **Observability** — analytics and crash reporting behind protocols, with Firebase adapters; non-fatals recorded with no per-feature wiring
- **Build** — three environments, privacy manifest, one-command rename

The service gates are driven by HTTP status, not by a version endpoint. A `426` blocks the app behind "Update Required" and a `503` behind "Back Soon", both routed through `SessionEventBus`. `APIConfig.isForceUpdateEnabled` and the `VersionCheck` model belong to a client-side version-comparison approach that isn't built — delete them, or wire them to a version endpoint if you prefer that shape.

Scaffolded but **not** wired — push notifications, see below.

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

## Hardening

Four opt-in protections. Two of them — jailbreak and anti-debug — are heuristic and report-only by design, so they flag rather than block.

> **Pinning is optional.** The app is fully safe and behaves like a normal HTTPS app while `PINNED_PUBLIC_KEY_HASHES` is left blank — an empty list means default TLS trust, no extra rules. You only need to fill it in once you have a real production backend and want the extra protection.

### Certificate pinning

Pins the server's **public key** (SPKI), not the certificate, so a certificate renewal with the same key doesn't break the app. Off in Development and Staging so local proxies (Charles, Proxyman) and self-signed certs still work; on in Production.

1. Generate the base64 SPKI hash for each endpoint's leaf certificate:

   ```bash
   openssl s_client -connect api.example.com:443 -showcerts </dev/null 2>/dev/null \
     | openssl x509 -pubkey -noout \
     | openssl pkey -pubin -outform der \
     | openssl dgst -sha256 -binary \
     | base64
   ```

2. Paste the output into `PINNED_PUBLIC_KEY_HASHES` in `Config/Production.xcconfig`, comma-separated for multiple keys.

The pinner compares that to the hash the running app computes from the server's presented certificate. Leave the list empty and it falls back to default TLS trust — a safe no-op until you add real hashes. A failed match surfaces as a `.serverTrustFailed` error.

### Screen-capture / app-switcher privacy

A `PrivacyShieldView` covers the UI whenever the app is not active, so the task-switcher snapshot is blank. iOS can't prevent screenshots, so instead the app detects them (`ScreenshotDetector`) and records a `screenshot_captured` analytics event — capture is observable, not blockable.

### Jailbreak detection

`JailbreakDetector` checks for the usual filesystem indicators (Cydia, Sileo, sshd, …). It is **report-only**: jailbreak checks are trivially bypassable and can false-positive, so the app flags the device in analytics rather than refusing to run.

### Anti-debug

`DebuggerDetector` reads the `P_TRACED` process flag via `sysctl` and reports an attached debugger. Deliberately no `ptrace(PT_DENY_ATTACH)` — that reads as anti-tampering to App Review and can get a submission rejected. Obfuscation beyond the existing Release symbol-stripping is intentionally not attempted.

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

Crashlytics symbols upload automatically. The `Upload Crashlytics dSYM` phase skips Development, which keeps its symbols in the binary, and sends Staging and Production to whichever Firebase project that configuration points at.

### Push is scaffolded, not wired

`FirebaseMessaging` is installed and configured, and `UserRepository` declares `registerForPushNotifications(token:)`. **Nothing calls it.** The app logs its FCM token and discards it, so no notification can reach a device. Finish it before relying on it.

- Ask for permission and call `registerForRemoteNotifications()`
- Set `Messaging.messaging().apnsToken` in `didRegisterForRemoteNotificationsWithDeviceToken`
- Send the FCM token to your backend, and clear it on sign-out
- Route taps through `AppNavigator`, which already handles deep links
- Add the **Push Notifications** capability, and upload an APNs `.p8` to each Firebase project

The last one needs a paid Apple Developer membership. FCM does not replace APNs on iOS — it forwards through it, and the `.p8` is what authorizes Firebase to do that on your behalf.

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

## Apple Developer account

Not needed to build, run, or develop against this template. The simulator needs nothing, and a free Apple ID signs builds onto your own device.

A paid membership is required for exactly two things.

- **Push notifications** — the capability and the APNs `.p8` are both members-only
- **Distribution** — TestFlight and the App Store

Everything else works without one, which is why push stays scaffolded rather than half-implemented.

## Before you ship

- Real API URLs in all three xcconfigs
- All three `GoogleService-Info.plist` files in place
- The `Item` sample removed
- Review `PrivacyInfo.xcprivacy` against what your backend stores
- App icon and accent color
