//
// SocketCollector.swift
//
//  Created by Krassi + AI
//

import Foundation

class SocketCollector: Collector {
    
    var webSocketConnectionFactory: WebSocketConnectionFactory = DefaultWebSocketConnectionFactory()
    var webSocketConnectionTask: Task<Void, Never>? = nil
    var connection: WebSocketConnection<Data, Data>? = nil

    var tracing: Bool
    let endpoint: String
    
    required init(_ endpoint: String, headers: [String: String]? = nil, tracing: Bool = false) {
        let url = URL(string: endpoint)!
        let connection: WebSocketConnection<Data, Data> = webSocketConnectionFactory.open(url: url)
        self.connection = connection
        self.tracing = tracing
        self.endpoint = endpoint
    }
 
    public func post(_ batch: Batch) async -> Policy.Action {
        
        let count = batch.events.count
        
        let retriedEvents = batch.events.filter { $0.retryCount > 1 }
                 
        if !retriedEvents.isEmpty {
            await LIFT.SDK.diagnostics?.report(.retried(
                retriedEvents.map { $0.id?.uuidString ?? "unknown" }
            ))
        }
        
        LIFT.Event.context?.performAndWait {
            batch.log(level:.info, "Sending \(count) event\(count != 1 ? "s" : "") in")
        }
        
        if (tracing) {
            // Puts time on each event when the attempt is made to send it
            // Subsequently this information ends up in the tracing record
            batch.trace()
        }
        
        do {
    
            let batchData = batch.data(endpoint: endpoint)
               
            try await connection?.send(batchData) // <- Socket network activity
            
            let cResp = try await connection?.receiveOnce()
            
            guard let code8 = cResp?.first else {
                LIFT.Event.context?.performAndWait {
                    LIFT.SDK.logger.log(level: .info, "Assuming HTTP post failed and will retry" )
                    batch.log(level: .warn, "")
                }
                return .retryUpToMax
            }
            
            let code = Int(code8)
            
            let bResp = try await connection?.receiveOnce()
            
            let responseBody = try? JSONDecoder().decode(ResponseBody.self, from: bResp!)
            
            let codePrefix = "HTTP \(code) received"
            
            switch code {
              case 200...299:
                await LIFT.SDK.diagnostics?.report(.succeeded([(code: code, count: count)]))
                LIFT.Event.context?.performAndWait {
                    batch.log(level: .info, "\(codePrefix). Will delete")
                }
                
                return .doNotRetry // "Success"
                
              case 423, 429:  // Temporary unavailability of the LIFT API
                LIFT.Event.context?.performAndWait {
                    batch.log(level: .info, "\(codePrefix), API throttling. Will retry")
                }
                return .retryUpToMax
                
              case 400...422, // Invalid events in the batch
                   424...428, // which were dropped,
                   430...499: // but no more serious errors occurred
                
                LIFT.Event.context?.performAndWait {
                    batch.log(level: .info, "\(codePrefix) for")
                }
                
                if let body = responseBody {
                    
                    let written_count = body.Written
                    
                    if written_count > 0 {
                        await LIFT.SDK.diagnostics?.report(.succeeded( [(code: code, count:written_count)] ))
                    }
                    
                    let invalidEvents = body.Events.filter { $0.Status == "invalid" }
                    
                    await LIFT.SDK.diagnostics?.report(.status_codes(  [(code: code, count: count - written_count)]  ))
                    
                    /* TODO: should I report dropped
                    await LIFT.SDK.diagnostics?.report(.dropped(
                        invalidEvents.map { $0.EventId }
                    ))*/
                    
                    
                    var output = "Errors:\n"
                    for event in invalidEvents {
                        
                        guard let errors = event.Errors else { continue }
                        
                        for error in errors {
                            output.append("\(error.Schema) : \(error.Failure)\n")
                        }
                    }
                    LIFT.SDK.logger.log(level:.info, output)
                    
                    LIFT.Event.context?.performAndWait {
                        batch.log(level: .info, "Will delete \( !invalidEvents.isEmpty ? "from" : "" ) ")
                    }
                    
                }
                
                /* - older endpoints
                let hasRejections = data.count > 0
                
                if (hasRejections) {
                    LIFT.SDK.logger.log(level:.info,
                        "API response:\n".appending(String(data: data.prefix(RESPONSE_LIMIT_LOG), encoding: .utf8) ?? "unknown")
                    )
                    
                    if(data.count > RESPONSE_LIMIT_LOG) {
                        LIFT.SDK.logger.log(level:.info, "\(data.count) bytes in total")
                    }
                }
                
                LIFT.Event.context?.performAndWait {
                    batch.log(level: .info, "Will delete \( hasRejections ? "from" : "" ) ")
                }*/
                
                return .doNotRetry
                
              case 500...599: // Temporary unavailability of the LIFT API
                await LIFT.SDK.diagnostics?.report(.status_codes(  [(code: code, count: count)]  ))
                return .retryUpToMax
                
              default:
                await LIFT.SDK.diagnostics?.report(.status_codes(  [(code: code, count: count)]  ))
                return .retryUpToMax
            }

        /*} catch let error as URLError {
            
            switch error.code {
              case URLError.Code.timedOut:
                log(level: .info, error.localizedDescription )
                return .retryUpToMax
              default:
                log(level: .info, error.localizedDescription )
                return .retryIndefinitely
            }*/
    
        } catch let error {
            LIFT.Event.context?.performAndWait {
                LIFT.SDK.logger.log(level: .error, "\( { $0.hasSuffix(".") ? String($0.dropLast(1)) :  $0}(error.localizedDescription) )")
                batch.log(level: .info, "for")
            }
            
            if let urlError = error as? URLError {
                await LIFT.SDK.diagnostics?.report(.http_errors(   [(code: urlError.code, count: count)]  ))
            }
            
            return .retryUpToMax
        }
    }
}
