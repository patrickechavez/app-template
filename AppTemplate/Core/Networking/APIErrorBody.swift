//
//  APIErrorBody.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

struct APIErrorBody: Sendable, Equatable {

    let message: String?

    let fieldErrors: [String: [String]]

    init(data: Data) {
        guard !data.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: data),
              let json = object as? [String: Any] else {

            self.message = Self.plainTextMessage(from: data)
            self.fieldErrors = [:]
            return
        }

        self.fieldErrors = Self.extractFieldErrors(from: json)
        self.message = Self.extractMessage(from: json)
    }

    init(message: String?, fieldErrors: [String: [String]] = [:]) {
        self.message = message
        self.fieldErrors = fieldErrors
    }

    private static let messageKeys = ["message", "error", "detail", "error_description", "title", "reason"]

    private static func extractMessage(from json: [String: Any]) -> String? {
        for key in messageKeys {
            guard let value = json[key] else { continue }

            if let string = value as? String, !string.isEmpty {
                return string
            }

            if let nested = value as? [String: Any], let inner = extractMessage(from: nested) {
                return inner
            }
        }
        return nil
    }

    private static func plainTextMessage(from data: Data) -> String? {
        guard data.count <= 500,
              let text = String(data: data, encoding: .utf8) else { return nil }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("<") else { return nil }
        return trimmed
    }

    private static func extractFieldErrors(from json: [String: Any]) -> [String: [String]] {
        guard let errors = json["errors"] ?? json["error"] ?? json["validation_errors"] else {
            return [:]
        }

        if let map = errors as? [String: Any] {
            return map.compactMapValues { value in
                if let list = value as? [String] { return list.isEmpty ? nil : list }
                if let single = value as? String { return [single] }
                return nil
            }
        }

        if let list = errors as? [[String: Any]] {
            var result: [String: [String]] = [:]
            for entry in list {
                let field = (entry["field"] ?? entry["name"] ?? entry["source"]) as? String
                let text = (entry["message"] ?? entry["detail"] ?? entry["description"]) as? String
                guard let field, let text else { continue }
                result[field, default: []].append(text)
            }
            return result
        }

        return [:]
    }
}
