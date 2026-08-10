//
//  LaunchOptions.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum LaunchOptions {

    static var isUITesting: Bool {
        #if DEBUG
        return has("-ui-testing")
        #else
        return false
        #endif
    }

    static var startsSignedOut: Bool {
        isUITesting && has("-signed-out")
    }

    static var disablesAnimations: Bool {
        isUITesting && !has("-keep-animations")
    }

    private static func has(_ flag: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(flag)
    }
}
