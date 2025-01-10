//
//  Batch.swift
//
//  Created by Krassi + AI
//

import Foundation


// Batch is the major object interacting with the table in the database




public struct Batch {
    
    let events: [LIFT.Event]
    
    func retryEvents(_ max: Int) -> [LIFT.Event] {
        return events.filter { $0.retryCount < max }
    }
    
    func deleteEvents(_ max: Int) -> [LIFT.Event] {
        return events.filter { $0.retryCount >= max }
    }
    
    
    // TODO: Consider throwing
    func data(endpoint: String?) -> Data {
        // TODO: Ensure min 1 event in batch
        var allBytes = Data("[".utf8)
        allBytes.append(events.first?.payload(endpoint: endpoint) ?? Data())
        for event in events.dropFirst() {
            guard let eventBytes = event.payload(endpoint: endpoint) else { continue }
            allBytes.append(Data(",".utf8))
            allBytes.append(eventBytes)
        }
        allBytes.append(Data("]".utf8))
        return allBytes
    }

    func updateCounters(_ val:Int16) {
        for event in events {
            
            if let schema = event.schema,
                   schema.contains("diagnostics") { // Do not increment for diagnostic event
                // event.log(level: .debug, "Skipped counter for diagnostic")
                continue
            }
            
            event.log(level:.debug, "\( val > 0 ? "In" : "De" )crementing attempt counter for" )
            event.retryCount = event.retryCount + val
        }
        do {
         try LIFTEvent.save()
        } catch {
            log(level:.error, "Failed to record attempt for \(events.count) events")
            LIFT.SDK.logger.log(level: .error, "\(error)")
        }
    }

    func delete(after max:Int = 0) {
        
        defer { for event in retryEvents(max) { event.log("Will retry") } }
        
        for event in deleteEvents(max) {
            event.log("Deleting")
            LIFTEvent.context?.delete(event)
            if let retries = LIFT.SDK.policy?.retries, max >= retries {
                Task {
                    await LIFT.SDK.diagnostics?.report(.dropped([event.id?.uuidString ?? "unknown"]))
                }
            }
        }
        do {
            try LIFTEvent.save()
        } catch {
            log(level:.error, "Failed to delete \(events.count) events")
            LIFT.SDK.logger.log(level: .error, "\(error)")
        }
    }
}
