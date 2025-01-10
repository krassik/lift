//
//  WebSocketConnectionFactory.swift
//  WebSocketClient
//
//  Created by Krassi + AI
//

import Foundation

/// A simple factory protocol for creating concrete instances of ``WebSocketConnection``.
public protocol WebSocketConnectionFactory {
    func open<Incoming: Decodable & Sendable, Outgoing: Encodable & Sendable>(url: URL) -> WebSocketConnection<Incoming, Outgoing>
}

/// A default implementation of ``WebSocketConnectionFactory``.
public final class DefaultWebSocketConnectionFactory: Sendable {
    private let urlSession: URLSession

    /// Initialise a new instance of ``WebSocketConnectionFactory``.
    ///
    /// - Parameters:
    ///   - urlSession: URLSession used for opening WebSockets.
    ///
    public init(
        urlSession: URLSession = URLSession.shared
    ) {
        self.urlSession = urlSession
    }
}

extension DefaultWebSocketConnectionFactory: WebSocketConnectionFactory {
    public func open<Incoming: Decodable & Sendable, Outgoing: Encodable & Sendable>(url: URL) -> WebSocketConnection<Incoming, Outgoing> {
        let request = URLRequest(url: url)
        let webSocketTask = urlSession.webSocketTask(with: request)

        return WebSocketConnection(
            webSocketTask: webSocketTask
        )
    }
}
