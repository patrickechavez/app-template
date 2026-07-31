//
//  ImageLoader.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import SwiftUI
import UIKit

protocol ImageLoading: Sendable {
    func image(for url: URL) async throws -> UIImage
    func evict(_ url: URL) async
    func clear() async
}

actor ImageLoader: ImageLoading {
    static let shared = ImageLoader()

    private let memory = NSCache<NSURL, UIImage>()
    private let directory: URL
    private let ttl: TimeInterval
    private let session: URLSession
    private let fileManager = FileManager.default

    init(ttl: TimeInterval = 7 * 24 * 60 * 60, session: URLSession = .shared) {
        self.ttl = ttl
        self.session = session
        let manager = FileManager.default
        let caches = manager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = memory.object(forKey: url as NSURL) {
            return cached
        }
        if let onDisk = diskImage(for: url) {
            memory.setObject(onDisk, forKey: url as NSURL)
            return onDisk
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let image = UIImage(data: data) else {
            throw ImageLoaderError.invalidImageData
        }
        memory.setObject(image, forKey: url as NSURL)
        try? data.write(to: fileURL(for: url), options: .atomic)
        return image
    }

    func evict(_ url: URL) {
        memory.removeObject(forKey: url as NSURL)
        try? fileManager.removeItem(at: fileURL(for: url))
    }

    func clear() {
        memory.removeAllObjects()
        try? fileManager.removeItem(at: directory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func diskImage(for url: URL) -> UIImage? {
        let file = fileURL(for: url)
        guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
              let modified = attributes[.modificationDate] as? Date else {
            return nil
        }
        if Date().timeIntervalSince(modified) > ttl {
            try? fileManager.removeItem(at: file)
            return nil
        }
        guard let data = try? Data(contentsOf: file) else { return nil }
        return UIImage(data: data)
    }

    private func fileURL(for url: URL) -> URL {
        let key = Data(url.absoluteString.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
        return directory.appendingPathComponent(key)
    }
}

enum ImageLoaderError: Error {
    case invalidImageData
}

// MARK: - Environment injection

private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: any ImageLoading = ImageLoader.shared
}

extension EnvironmentValues {
    var imageLoader: any ImageLoading {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}
