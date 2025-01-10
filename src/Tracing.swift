//
//  Tracing.swift
//  
//
//  Created by Krassi + AI
//

import Foundation
import CoreData

public class LIFTAttempt: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        timestamp = Date.now.epoch
    }
}


extension LIFTAttempt {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LIFTAttempt> {
        return NSFetchRequest<LIFTAttempt>(entityName: "LIFTAttempt")
    }

    // @NSManaged public var event_id: UUID
    @NSManaged public var counter: Int16
    @NSManaged public var timestamp: Int64
    @NSManaged public var event: LIFTEvent?
}


extension LIFT.Event {
    func trace() {
        guard let context = managedObjectContext else { return }
        let attempt = LIFT.Attempt(context: context)
        attempt.event = self
        attempt.counter = retryCount
        addToAttempts(NSSet(object: attempt))
    }
    
    func payload(endpoint: String?) -> Data? {
        
        // let  header = "{ \"from\": \"app\", \"to\": \"sdk\", \"ts\": \(timestamp), \"attempt\": \(0) }"
        
        guard let load = payload else { return nil }
        guard let attempts = attempts, attempts.count > 0 else { return load }
        
        let trace = attempts.map {
            
            let attempt = $0 as? LIFT.Attempt
            
            return """
               { "from": "sdk",
                 "to": \"\(endpoint ?? "api")\",
                 "ts": \( attempt?.timestamp ?? -1 ),
                 "attempt": \( attempt?.counter ?? -1)
               }
             """
        }.joined(separator: ",")
        
        var data = Data("""
            { "trace" : [ \(trace) ],
        """.utf8)
        data.append( load.dropFirst() )
        return data
    }
}

extension Batch {
    func trace() {
        for event in events {
            event.trace()
        }
        do {
            try LIFTEvent.save()
        } catch {
            log(level:.error, "Failed to trace \(events.count) events")
            LIFT.SDK.logger.log(level: .error, "\(error)")
        }
    }
}
