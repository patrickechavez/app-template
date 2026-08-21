//
//  ScreenshotDetector.swift
//  AppTemplate
//  Created by John Patrick Echavez on 8/16/26.
//

import UIKit

// Detects when the user takes a screenshot of the app.
enum ScreenshotDetector {

    static var publisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
    }
}
