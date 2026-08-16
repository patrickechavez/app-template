//
//  ScreenshotDetector.swift
//  AppTemplate
//  Created by John Patrick Echavez on 8/16/26.
//

import UIKit

/// Emits when the user takes a screenshot. iOS cannot prevent a screenshot —
/// this makes captures observable so they can be flagged in analytics.
enum ScreenshotDetector {

    static var publisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
    }
}
