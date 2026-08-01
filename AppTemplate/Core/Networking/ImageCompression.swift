//
//  ImageCompression.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import UIKit

struct ImageCompression {
    let maxDimension: CGFloat
    let quality: CGFloat
    var maxBytes: Int? = nil

    static let thumbnail = ImageCompression(maxDimension: 256, quality: 0.7)
    static let profile = ImageCompression(maxDimension: 512, quality: 0.8)
    static let fullScreen = ImageCompression(maxDimension: 2048, quality: 0.8)
    static let document = ImageCompression(maxDimension: 3000, quality: 0.9)

    static func custom(maxDimension: CGFloat,
                       quality: CGFloat,
                       maxBytes: Int? = nil) -> ImageCompression {
        ImageCompression(maxDimension: maxDimension, quality: quality, maxBytes: maxBytes)
    }
}

extension UIImage {
    func jpegData(for compression: ImageCompression) -> Data? {
        if let maxBytes = compression.maxBytes {
            return jpegDataForUpload(maxBytes: maxBytes, maxDimension: compression.maxDimension)
        }
        return jpegDataForUpload(maxDimension: compression.maxDimension, quality: compression.quality)
    }
}
