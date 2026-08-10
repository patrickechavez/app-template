//
//  ImageLoader.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import CryptoKit
import SwiftUI
import UIKit
import os

protocol ImageLoading: Sendable {
    func image(for url: URL) async throws -> UIImage
    func evict(_ url: URL) async
    func clear() async

    func trimMemory() async
}

enum ImageLoaderError: Error, Equatable {
    case invalidImageData
    case httpStatus(Int)
}

actor ImageLoader: ImageLoading {

    static let shared = ImageLoader()

    private let memoryCountLimit = 100
    private let memoryCostLimit = 100 * 1024 * 1024

    private let diskCapacity = 200 * 1024 * 1024

    private let ttl: TimeInterval

    private let memory = NSCache<NSURL, UIImage>()
    private let directory: URL
    private let session: URLSession
    private let fileManager = FileManager.default

    private var inFlight: [URL: Task<UIImage, any Error>] = [:]

    private var bytesWrittenSinceSweep = 0
    private let sweepThreshold = 10 * 1024 * 1024

    init(ttl: TimeInterval = 7 * 24 * 60 * 60, session: URLSession = .shared) {
        self.ttl = ttl
        self.session = session

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        memory.countLimit = memoryCountLimit
        memory.totalCostLimit = memoryCostLimit
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = memory.object(forKey: url as NSURL) {
            return cached
        }

        if let onDisk = diskImage(for: url) {
            store(onDisk, inMemoryFor: url)
            return onDisk
        }

        if let existing = inFlight[url] {
            return try await existing.value
        }

        let task = Task<UIImage, any Error> { [session] in
            let (data, response) = try await session.data(from: url)

            guard let http = response as? HTTPURLResponse else {
                throw ImageLoaderError.invalidImageData
            }
            guard (200..<300).contains(http.statusCode) else {
                throw ImageLoaderError.httpStatus(http.statusCode)
            }
            guard let image = UIImage(data: data) else {
                throw ImageLoaderError.invalidImageData
            }

            return image
        }
        inFlight[url] = task

        do {
            let image = try await task.value
            inFlight[url] = nil
            store(image, inMemoryFor: url)
            writeToDisk(image, for: url)
            return image
        } catch {
            inFlight[url] = nil
            throw error
        }
    }

    func evict(_ url: URL) {
        memory.removeObject(forKey: url as NSURL)
        try? fileManager.removeItem(at: fileURL(for: url))
    }

    func clear() {
        memory.removeAllObjects()
        try? fileManager.removeItem(at: directory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        bytesWrittenSinceSweep = 0
    }

    func trimMemory() {
        memory.removeAllObjects()
    }

    private func store(_ image: UIImage, inMemoryFor url: URL) {
        memory.setObject(image, forKey: url as NSURL, cost: image.estimatedBytes)
    }

    private func diskImage(for url: URL) -> UIImage? {
        let file = fileURL(for: url)

        guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
              let modified = attributes[.modificationDate] as? Date else {
            return nil
        }

        guard Date().timeIntervalSince(modified) <= ttl else {
            try? fileManager.removeItem(at: file)
            return nil
        }

        guard let data = try? Data(contentsOf: file) else { return nil }
        return UIImage(data: data)
    }

    private func writeToDisk(_ image: UIImage, for url: URL) {

        guard let data = image.jpegData(compressionQuality: 0.9) else { return }

        do {
            try data.write(to: fileURL(for: url), options: .atomic)
            bytesWrittenSinceSweep += data.count

            if bytesWrittenSinceSweep >= sweepThreshold {
                bytesWrittenSinceSweep = 0
                sweepDiskCache()
            }
        } catch {
            AppLogger.images.error("Could not write cache entry: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func sweepDiskCache() {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey]

        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys
        ) else {
            return
        }

        let entries = files.compactMap { url -> (url: URL, date: Date, size: Int)? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  let date = values.contentModificationDate,
                  let size = values.fileSize else { return nil }
            return (url, date, size)
        }

        let total = entries.reduce(0) { $0 + $1.size }
        guard total > diskCapacity else { return }

        let target = Int(Double(diskCapacity) * 0.8)
        var remaining = total

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            guard remaining > target else { break }
            try? fileManager.removeItem(at: entry.url)
            remaining -= entry.size
        }

        let before = total / 1024 / 1024
        let after = remaining / 1024 / 1024
        AppLogger.images.debug(
            "Swept image cache: \(before, privacy: .public)MB → \(after, privacy: .public)MB"
        )
    }

    private func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name)
    }
}

private extension UIImage {

    var estimatedBytes: Int {
        guard let cgImage else { return 1 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: any ImageLoading = ImageLoader.shared
}

extension EnvironmentValues {
    var imageLoader: any ImageLoading {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}
