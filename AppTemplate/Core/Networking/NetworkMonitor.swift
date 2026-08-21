//
//  NetworkMonitor.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation
import Network
import Observation
import os

// Monitors if the device is connected to the internet.
@Observable
@MainActor
final class NetworkMonitor {

    private(set) var isConnected = true

    private(set) var isExpensive = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let queue = DispatchQueue(label: "network.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let expensive = path.isExpensive

            Task { @MainActor [weak self] in
                self?.apply(isConnected: connected, isExpensive: expensive)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func apply(isConnected connected: Bool, isExpensive expensive: Bool) {
        AppLogger.network.debug(
            "Path update, connected \(connected, privacy: .public), expensive \(expensive, privacy: .public)"
        )

        isExpensive = expensive

        guard connected != isConnected else { return }
        isConnected = connected

        AppLogger.network.notice("Connectivity \(connected ? "restored" : "lost", privacy: .public)")
    }
}
