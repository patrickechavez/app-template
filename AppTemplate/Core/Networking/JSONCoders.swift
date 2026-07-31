//
//  JSONCoders.swift
//  AppTemplate
//
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

// Centralized JSON coders for all API traffic.
//
// Dates cross the wire as ISO 8601 in UTC (e.g. "2026-07-31T16:30:00Z"). The
// app converts to the device's local timezone only for display. The decoder
// tolerates timestamps WITH or WITHOUT fractional seconds, which different
// backends emit.

extension JSONEncoder {
    /// Encoder for outgoing requests — sends `Date` as ISO 8601 (UTC).
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    /// Decoder for incoming responses — parses ISO 8601 `Date` (UTC),
    /// tolerant of fractional seconds.
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601Tolerant
        return decoder
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    /// Accepts ISO 8601 timestamps with or without fractional seconds.
    static var iso8601Tolerant: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            let withFractional = ISO8601DateFormatter()
            withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]

            if let date = withFractional.date(from: string) ?? standard.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO 8601 date, got \"\(string)\""
            )
        }
    }
}
