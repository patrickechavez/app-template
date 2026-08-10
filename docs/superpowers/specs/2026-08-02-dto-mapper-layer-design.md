# DTO + Mapper Layer — Design

**Date:** 2026-08-02
**Status:** Approved for planning
**Scope:** Add an opt-in DTO → domain → mapper pattern to the AppTemplate boilerplate, demonstrated with one worked example (`Item`), while keeping plain `Codable` models the default for clean 1:1 APIs.

---

## Motivation

The template currently uses shared models: `User` and `Item` are single `Codable` structs that are both the wire format *and* the type the UI renders. `AuthResponse.tokens` is the one existing exception — a DTO whose computed property maps to the domain `AuthTokens`.

The goal is **not** to mandate DTOs everywhere. Mandatory separation is a per-resource tax that every project inherits forever, and it produces empty 1:1 mappers that hide bugs while doing nothing. For a template that teams apply, the valuable thing to propagate is *judgment*: put the boundary where change actually crosses.

This design therefore establishes the DTO pattern as a **documented, opt-in escalation** — demonstrated correctly once, with a written rule for when to use it — and keeps plain `Codable` as the default.

## The decision rule (the core deliverable)

The most important artifact is the rule that tells the next developer when to reach for a DTO. It lives in the README and as a doc comment on the `DTO` protocol:

> **Use a plain `Codable` model when** the API's JSON maps 1:1 to what your UI needs — you control the backend, fields are clean, and wire types match your domain types.
>
> **Add a DTO + mapper when** the wire shape diverges from your domain: messy or inconsistent JSON, fields you must rename or drop, wire types weaker than your domain types (a `String` that is really a URL, a raw int that is really an enum), or an API you do not control.

`User` is deliberately left as a plain `Codable` model so the template shows *both* sides of this rule side by side. `Item` becomes the DTO-backed example. The contrast is part of the teaching.

## Architecture

Mapping happens in exactly one place — the repository — which is the seam between the networking layer (wire types) and everything above it (domain types). Views and view models never see a DTO.

```
API JSON ──decode──▶ ItemDTO ──toDomain()──▶ Item ──▶ ViewModel ──▶ View
                    (wire shape)            (domain)
                          └──────── LiveItemRepository ────────┘
```

### Component 1 — the `DTO` protocol (shared plumbing)

New file `Core/Networking/DTO.swift`:

```swift
/// A wire-format model that knows how to become its domain equivalent.
///
/// Conform when an endpoint's JSON diverges from what your app wants to work
/// with. For a clean 1:1 resource, a plain `Codable` domain model is simpler —
/// see the decision rule in the README.
protocol DTO: Decodable, Sendable {
    associatedtype Domain
    func toDomain() throws -> Domain
}

extension Page {
    /// Maps a page of DTOs to a page of domain models, preserving the
    /// pagination metadata. This is why the `DTO` protocol earns its keep:
    /// without it, mapping a paginated response is verbose in every repository.
    func map<T>(_ transform: (Element) throws -> T) rethrows -> Page<T> {
        Page<T>(
            items: try items.map(transform),
            total: total,
            offset: offset,
            limit: limit,
            nextCursor: nextCursor
        )
    }
}
```

**What it does:** standardises the wire→domain conversion and provides the one generic helper (`Page.map`) that keeps paginated repositories clean.
**Depends on:** `Page` (existing).

### Component 2 — `ItemDTO` (the worked wire model)

New file `Data/DTOs/ItemDTO.swift`:

```swift
struct ItemDTO: DTO {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let thumbnail: String?          // raw string, exactly as the API sends it

    func toDomain() throws -> Item {
        // A mapping failure is a contract mismatch — the same category as a
        // JSON decode failure — so it reuses the existing error taxonomy and
        // flows straight into the error handling the app already has.
        guard !title.isEmpty else {
            throw APIError.decodingFailed(detail: "Item \(id): title was empty")
        }
        guard price >= 0 else {
            throw APIError.decodingFailed(detail: "Item \(id): negative price \(price)")
        }

        return Item(
            id: id,
            title: title,
            description: description,
            price: price,
            thumbnailURL: thumbnail.flatMap(URL.init(string:))  // String -> URL
        )
    }
}
```

**What it does:** mirrors the wire shape, then validates and converts to the domain `Item`. The empty-title / negative-price guards make the throwing path real and testable, not theoretical.
**Depends on:** `Item` (domain), `APIError`, `DTO`.

**snake_case is a DTO concern.** The shared `JSONDecoder.api` does not use `.convertFromSnakeCase`; the template's convention is explicit `CodingKeys` per model (as `VersionCheck` already does). When an API sends snake_case, the `CodingKeys` live **on the DTO** and never touch the domain `Item`:

```swift
struct ItemDTO: DTO {
    let id: Int
    let imageURL: String?
    enum CodingKeys: String, CodingKey {
        case id
        case imageURL = "image_url"   // wire concern, contained on the DTO
    }
}
```

The sample `dummyjson` API sends clean single-word keys (`id`, `title`, `price`, `thumbnail`), so the worked `ItemDTO` needs no `CodingKeys`. The domain `Item` never has `CodingKeys` at all — keeping wire naming off the domain type is part of what the DTO buys you.

### Component 3 — `Item` as a domain model

Edit `Models/Models.swift`. `Item` **loses** `Codable` and gains the stronger stored type:

```swift
struct Item: Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let thumbnailURL: URL?          // was `thumbnail: String?` + computed accessor
}
```

The `thumbnailURL` computed property is removed — it is now a stored property populated by the mapper. `Identifiable/Equatable/Hashable/Sendable` stay (they are domain concerns: `ForEach`, navigation, mocks).

### Component 4 — the repository does the mapping

Edit `Data/ItemRepository.swift`. The protocol is unchanged (it still returns domain `Page<Item>` / `Item`); only the implementation changes to decode DTOs and map:

```swift
func items(_ request: PageRequest) async throws -> Page<Item> {
    try await (api.get(APIRoute.Items.list, query: request.queryItems) as Page<ItemDTO>)
        .map { try $0.toDomain() }
}

func item(id: Int) async throws -> Item {
    try await (api.get(APIRoute.Items.detail(id)) as ItemDTO).toDomain()
}

func search(_ term: String, page: PageRequest) async throws -> Page<Item> {
    var query = page.queryItems
    query.append(URLQueryItem(name: "q", value: term))
    return try await (api.get(APIRoute.Items.search, query: query) as Page<ItemDTO>)
        .map { try $0.toDomain() }
}
```

`create` / `update` return the created resource, so they map their response the same way. `delete` is unchanged.

**Request bodies** (`ItemDraft`, `RegisterRequest`, …) are already request DTOs — plain `Encodable`. They stay exactly as they are; the doc notes not to wrap them.

## Error handling

Mapping failures throw `APIError.decodingFailed(detail:)` directly (decision confirmed). Rationale: a DTO that cannot become a valid domain object is a contract mismatch — the same bucket as a JSON decode failure — so it reuses the existing taxonomy and the UI's existing error path. The mild coupling (the mapper references `APIError`) is acceptable because both are data-layer types. `Page.map` and the repository let the throw propagate untouched.

## File layout

```
Core/Networking/DTO.swift        // protocol + Page.map            (new)
Models/Models.swift              // Item: Codable -> domain model  (edit)
Data/DTOs/ItemDTO.swift          // wire model + toDomain()         (new)
Data/ItemRepository.swift        // decode DTO, map to domain       (edit)
```

`User` and every other model are left untouched as plain `Codable`, demonstrating the default side of the decision rule.

## Ripple

Making `Item` non-`Codable` has a bounded, known blast radius:

- **`DecodingTests.swift`** — tests that decode `Page<Item>` from JSON move to `Page<ItemDTO>`. New mapper coverage is added (see Testing).
- **`Mocks.swift`** — `SampleData.items` and `MockItemRepository` build domain `Item` directly (not by decoding), so they are unaffected. A `SampleData.itemDTO` may be added for mapper tests.
- **Views / view models** — no change. They already consume domain `Item`; `item.thumbnailURL` is now a stored property instead of computed, which is source-compatible at every call site.
- **`User`, `AuthResponse`, other models** — untouched.

## Testing

New `MappingTests` suite (`AppTemplateTests/MappingTests.swift`):

- `ItemDTO.toDomain()` maps a valid DTO, including `String` → `URL`.
- `toDomain()` throws `APIError.decodingFailed` on empty title and on negative price.
- `toDomain()` with a `nil`/malformed `thumbnail` yields `thumbnailURL == nil` rather than throwing.
- `Page.map` preserves `total` / `offset` / `limit` / `nextCursor` while transforming elements.

`DecodingTests` is updated to decode `Page<ItemDTO>`. The rest of the existing suite (auth, networking, view models, navigation) stays green with no changes.

## Documentation

- The decision rule goes into the README's "Adding a feature" section, with the `Item` conversion shown as the worked example alongside the note that `User` stays plain `Codable` on purpose.
- A doc comment on the `DTO` protocol points back to the rule.
- A one-line note that request bodies are already DTOs and need no domain counterpart.

## Out of scope

- Converting `User` or any other existing model to a DTO.
- Outbound domain→request-DTO mapping beyond the existing `Encodable` request types.
- A generic decode-and-map convenience on `APIClient` (`get<D: DTO>(…) -> D.Domain`). Deliberately omitted: keeping the mapping explicit in the repository is where the pattern should be *visible* for the next developer to learn it.

## Success criteria

- All three schemes build with zero warnings under Swift 6.
- Full test suite green, including the new `MappingTests`.
- SwiftLint `--strict` and preflight pass.
- A developer reading the repository can see exactly where wire becomes domain, and the README tells them when to repeat the pattern versus when to use a plain model.
