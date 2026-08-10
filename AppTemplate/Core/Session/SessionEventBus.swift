//
//  SessionEventBus.swift
//  AppTemplate
//  Created by John Patrick Echavez on 7/29/26.
//

import Foundation

enum SessionEvent: Sendable, Equatable {

    case expired

    case updateRequired(message: String?)

    case maintenance(message: String?)
}

final class SessionEventBus: Sendable {

    let events: AsyncStream<SessionEvent>

    private let continuation: AsyncStream<SessionEvent>.Continuation

    init() {

        let (stream, continuation) = AsyncStream<SessionEvent>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        self.events = stream
        self.continuation = continuation
    }

    func send(_ event: SessionEvent) {
        continuation.yield(event)
    }

    func finish() {
        continuation.finish()
    }
}
