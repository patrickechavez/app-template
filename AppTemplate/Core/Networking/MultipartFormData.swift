//
//  MultipartFormData.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import UIKit

struct MultipartFormData {
    let boundary: String
    private var body = Data()

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    mutating func addField(_ name: String, value: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func addFile(_ name: String, filename: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        append("\r\n")
    }

    mutating func addImage(_ image: UIImage,
                           name: String,
                           filename: String = "image.jpg",
                           maxDimension: CGFloat = 2048,
                           quality: CGFloat = 0.8) {
        guard let data = image.jpegDataForUpload(maxDimension: maxDimension, quality: quality) else { return }
        addFile(name, filename: filename, mimeType: "image/jpeg", data: data)
    }

    func encoded() -> Data {
        var data = body
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }

    private mutating func append(_ string: String) {
        body.append(Data(string.utf8))
    }
}
