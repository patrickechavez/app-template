//
//  Page.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

struct Page<Element: Decodable & Sendable>: Decodable, Sendable {

    static var collectionKeys: [String] {
        ["items", "data", "results", "records", "content", "products"]
    }

    let items: [Element]

    let total: Int?

    let offset: Int

    let limit: Int

    let nextCursor: String?

    var hasMore: Bool {
        if let nextCursor, !nextCursor.isEmpty { return true }
        if let total { return offset + items.count < total }
        return items.count >= limit && limit > 0
    }

    var nextOffset: Int? {
        hasMore ? offset + items.count : nil
    }

    init(items: [Element], total: Int? = nil, offset: Int = 0, limit: Int = 20, nextCursor: String? = nil) {
        self.items = items
        self.total = total
        self.offset = offset
        self.limit = limit
        self.nextCursor = nextCursor
    }

    private struct Key: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
        init(_ name: String) { self.stringValue = name }
    }

    init(from decoder: any Decoder) throws {

        if var unkeyed = try? decoder.unkeyedContainer() {
            var decoded: [Element] = []
            decoded.reserveCapacity(unkeyed.count ?? 0)
            while !unkeyed.isAtEnd {
                decoded.append(try unkeyed.decode(Element.self))
            }
            self.items = decoded
            self.total = decoded.count
            self.offset = 0
            self.limit = decoded.count
            self.nextCursor = nil
            return
        }

        let container = try decoder.container(keyedBy: Key.self)

        guard let collection = Self.collectionKeys
            .lazy
            .compactMap({ try? container.decode([Element].self, forKey: Key($0)) })
            .first
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: """
                    No array of \(Element.self) found under any of \
                    \(Self.collectionKeys). Add your backend's collection key \
                    to Page.collectionKeys.
                    """
                )
            )
        }

        self.items = collection

        let meta = try? container.nestedContainer(keyedBy: Key.self, forKey: Key("meta"))

        func int(_ names: [String]) -> Int? {
            for name in names {
                if let value = try? container.decode(Int.self, forKey: Key(name)) { return value }
                if let value = try? meta?.decode(Int.self, forKey: Key(name)) { return value }
            }
            return nil
        }

        self.total = int(["total", "count", "total_count", "totalCount", "totalElements"])
        self.offset = int(["skip", "offset", "from"]) ?? 0
        self.limit = int(["limit", "per_page", "perPage", "pageSize", "size"]) ?? collection.count
        self.nextCursor = ["next_cursor", "nextCursor", "next"]
            .lazy
            .compactMap { try? container.decode(String.self, forKey: Key($0)) }
            .first
    }
}

struct PageRequest: Sendable, Equatable {

    var limit: Int
    var offset: Int
    var cursor: String?

    var query: [URLQueryItem]

    init(limit: Int = 20, offset: Int = 0, cursor: String? = nil, query: [URLQueryItem] = []) {
        self.limit = limit
        self.offset = offset
        self.cursor = cursor
        self.query = query
    }

    static let first = PageRequest()

    func next<T>(after page: Page<T>) -> PageRequest? {
        guard page.hasMore else { return nil }
        var next = self
        next.offset = page.nextOffset ?? offset + page.items.count
        next.cursor = page.nextCursor
        return next
    }

    var queryItems: [URLQueryItem] {
        var items = query
        items.append(URLQueryItem(name: "limit", value: String(limit)))
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        } else {
            items.append(URLQueryItem(name: "skip", value: String(offset)))
        }
        return items
    }
}
