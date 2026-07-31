//
//  UIImage+Upload.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import UIKit

extension UIImage {
    func resizedForUpload(maxDimension: CGFloat = 2048) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: target).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    func jpegDataForUpload(maxDimension: CGFloat = 2048, quality: CGFloat = 0.8) -> Data? {
        resizedForUpload(maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    func jpegDataForUpload(maxBytes: Int, maxDimension: CGFloat = 2048) -> Data? {
        let image = resizedForUpload(maxDimension: maxDimension)
        var quality: CGFloat = 0.85
        var data = image.jpegData(compressionQuality: quality)
        while let current = data, current.count > maxBytes, quality > 0.3 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }
        return data
    }
}
