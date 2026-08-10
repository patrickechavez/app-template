//
//  MetadataInterceptor.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

struct MetadataInterceptor: RequestInterceptor {

    private let metadata: any RequestMetadataProviding

    init(metadata: any RequestMetadataProviding = ClientMetadata()) {
        self.metadata = metadata
    }

    func adapt(_ request: URLRequest, for endpoint: Endpoint) async throws -> URLRequest {
        var request = request
        for (field, value) in metadata.headers {

            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
