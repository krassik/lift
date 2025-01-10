//
//  Collector.swift
//
//
//  Created by Krassi + AI
//

import Foundation

public protocol Collector {
    init(_ endpoint: String, headers: [String: String]?, tracing: Bool)
    func post(_ batch: Batch) async -> Policy.Action
}

extension URLSession {
    
    func dataOrError(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)
    {
        try await ( Bool.random()
        
        ? { throw
            URLError(
            [ URLError.Code.timedOut,
              URLError.Code.networkConnectionLost,
              URLError.Code.dnsLookupFailed,
              URLError.Code.cannotConnectToHost,
              URLError.Code.cannotFindHost
            ] .randomElement()!)
          }
        
        : { try await self.data(for: request, delegate: delegate) } )()
    }
}


struct ResponseBody: Decodable {

    struct Event: Decodable {
        
        struct Error: Decodable {
            let Schema: String
            let Failure: String
        }
        
        let EventId: String
        let Status: String
        let Errors: [Error]?
    }
    
    let Written: Int
    let Total: Int
    let Events: [Event]
}

// Available to access private members during test

// public
extension HTTPCollector {
    func setRequestTimeout(_ interval: TimeInterval) {
        request.timeoutInterval = interval
    }
}
