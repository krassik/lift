//
//  WebSocketConnection.swift
//  WebSocketClient
//
//  Created by Krassi + AI
//

import Foundation

/// Enumeration of possible errors that might occur while using ``WebSocketConnection``.
public enum WebSocketConnectionError: Error {
    case connectionError
    case transportError
    case decodingError
    case disconnected
    case closed
}

/// A generic WebSocket Connection over an expected `Incoming` and `Outgoing` message type.
public final class WebSocketConnection<Incoming: Decodable & Sendable, Outgoing: Encodable & Sendable>: NSObject, Sendable {
    private let webSocketTask: URLSessionWebSocketTask

    internal init(
        webSocketTask: URLSessionWebSocketTask
    ) {
        self.webSocketTask = webSocketTask

        super.init()

        webSocketTask.resume()
    }

    deinit {
        // Make sure to cancel the WebSocketTask (if not already canceled or completed)
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }

    private func receiveSingleMessage() async throws -> Incoming {
        switch try await webSocketTask.receive() {
            case let .data(messageData):
                return messageData as! Incoming

            case let .string(text):
                assertionFailure("Did not expect to receive message as text")

                // Alternative 1: Unsupported data, closing the WebSocket Connection
                // webSocketTask.cancel(with: .unsupportedData, reason: nil)
                // throw WebSocketConnectionError.decodingFailure

                // Alternative 1: Try to parse the message data anyway
                guard
                    let messageData = text.data(using: .utf8)
                else {
                    throw WebSocketConnectionError.decodingError
                }

                // return message
                return text as! Incoming

            @unknown default:
                assertionFailure("Unknown message type")

                // Unsupported data, closing the WebSocket Connection
                webSocketTask.cancel(with: .unsupportedData, reason: nil)
                throw WebSocketConnectionError.decodingError
        }
    }
}

// MARK: Public Interface

public extension WebSocketConnection {
    func send(_ message: Outgoing) async throws {
       
        do {
            try await webSocketTask.send(.data(message as! Data))
        } catch {
            switch webSocketTask.closeCode {
                case .invalid:
                    throw WebSocketConnectionError.connectionError

                case .goingAway:
                    throw WebSocketConnectionError.disconnected

                case .normalClosure:
                    throw WebSocketConnectionError.closed

                default:
                    throw WebSocketConnectionError.transportError
            }
        }
    }

    func receiveOnce() async throws -> Incoming {
        do {
            return try await receiveSingleMessage()
        } catch let error as WebSocketConnectionError {
            throw error
        } catch {
            switch webSocketTask.closeCode {
                case .invalid:
                    throw WebSocketConnectionError.connectionError

                case .goingAway:
                    throw WebSocketConnectionError.disconnected

                case .normalClosure:
                    throw WebSocketConnectionError.closed

                default:
                    throw WebSocketConnectionError.transportError
            }
        }
    }

    func receive() -> AsyncThrowingStream<Incoming, Error> {
        AsyncThrowingStream { [weak self] in
            guard let self else {
                // Self is gone, return nil to end the stream
                return nil
            }

            let message = try await self.receiveOnce()

            // End the stream (by returning nil) if the calling Task was canceled
            return Task.isCancelled ? nil : message
        }
    }

    func close() {
        webSocketTask.cancel(with: .normalClosure, reason: nil)
    }
}
