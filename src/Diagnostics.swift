//
//  Diagnostics.swift
//  
//
//  Created by Krassi + AI
//

import Foundation
import CoreData
import AVFoundation
import UIKit

/// The class responsible for saving diagnostics information
///
///  Creating instance of this class will start collection
public actor Diagnostics {
    
    ///  trigger can hold on to a timer useful to control short interval for test
    ///    nil is valid  value for this trigger; nil is when 1 day cycle os invoked
    static var trigger: Timer?
    
    /// Catalog of HTTP error codes and custom string representaton
    /// Useful in log files
    static let http_error_codes  : [URLError.Code : String] = [
        .timedOut                : "timeOut",
        .networkConnectionLost   : "networkConnectionLost",
        .dnsLookupFailed         : "dnsLookupFailed",
        .cannotConnectToHost     : "cannotConnectToHost",
        .cannotFindHost          : "cannotFindHost"
    ]
    
    /// container is reponsible for peristing diagnostics informaton during app restarts
    let container = UserDefaults(suiteName: "LIFT.sdk.diagnostics")!
    
    var start: Date
    /// Diagnostics message schema is assigned at initialization an does not mutate
    let schema: String
    
    enum Priority: String {
        case netConnected = "Network: status=connected"
        case netDisconnected = "Network: status=disconnected"
        case netUnknown = "Network: status=unknown"
        case lowMemoryCondition = "Memory: status=low"
    }
    
    /// The type of counters asked by the specification
    enum Counter: CustomStringConvertible {
        case dropped([String])
        // case http_error(URLError.Code, times: Int = 1)
        case http_errors([(code: URLError.Code, count: Int)])
        // case status_code(Int, times: Int = 1)
        case status_codes([(code: Int, count: Int)])
        case priority_log([Priority])
        case received([String])
        case retried([String])
        case succeeded([(code: Int, count: Int)])
        
        var description : String {
          switch self {
              case .dropped(_):       return "dropped"
              case .http_errors(_):    return "http_error"
              case .status_codes(_):   return "status_code"
              case .priority_log(_):  return "priority_logs"
              case .received(_):      return "received"
              case .retried(_):       return "retried"
              case .succeeded(_):     return "succeeded"
          }
        }
    }
    
    // MARK: COUNTERS
    // Each conter will save/resume individually unaffectful of the rest
    
    @Stored(key:  Counter.dropped([]).description  )
    var dropped: [String:Int] = [:]
        
    //@Stored(key:  Counter.http_error(URLError.Code.unknown).description  )
    @Stored(key:  Counter.http_errors([]).description  )
    var http_errors: [String:Int] = [:]
    
    @Stored(key:  Counter.status_codes([]).description  )
    var status_codes: [String:Int] = [:]
    
    @Stored(key:  Counter.priority_log([]).description  )
    var priority_logs: [String:Int] = [:]
    
    // Derivation from stored records
    var queued: [String: Int] {
        
        let keypathExp = NSExpression(forKeyPath: "schema")
        let expression = NSExpression(forFunction: "count:", arguments: [keypathExp])

        let countDesc = NSExpressionDescription()
        countDesc.expression = expression
        countDesc.name = "count"
        countDesc.expressionResultType = .integer16AttributeType
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LIFTEvent")
        request.returnsObjectsAsFaults = false
        request.propertiesToGroupBy = ["schema"]
        request.propertiesToFetch = ["schema", countDesc]
        request.resultType = .dictionaryResultType
        
        request.predicate = NSPredicate(format: "retryCount = 0") // not retried
        
        var breakdown = [String:Int]()
        
        for aggregation in (try? LIFT.Event.context?.fetch(request) as? [[String:Any]]) ?? [] {
            breakdown[ aggregation["schema"] as? String ?? "unknown" ] = aggregation["count"] as? Int ?? 0
        }
        
        return breakdown
    }
    
    @Stored(key:  Counter.received([]).description  )
    var received: [String:Int] = [:]
    
    @Stored(key:  Counter.retried([]).description  )
    var retried: [String:Int] = [:]
    
    @Stored(key:  Counter.succeeded([]).description  )
    var succeeded: [String:Int] = [:]
    
    // MARK: BEHAVIOUR
    
    func updateSingle<T>(_ table: inout [T: Int], for counter: T, value: Int = 1) {
        guard table[counter] != nil else {
            table[counter] = value
            return
        }
        
        table[counter]! = table[counter]! + value
    }
    
    func updateMultiple<T>(_ table: inout [T: Int], for counters: [(name: T, value: Int)]) {
        
        for counter in counters {
            updateSingle(&table, for: counter.name, value: counter.value)
        }
    }
    
    static func makeUnit<T>(_ item: T) -> (T,Int) { (item, 1) }
    
    static func makeUnits<T>(_ items: [T]) -> [(T,Int)] { items.map { makeUnit($0) } }
    
    /// The method signature is optimized for concise notation at the call site
    func report(_ counter: Counter) {
        
        //let code = Diagnostics.http_error_codes.keys.randomElement()!
        
        switch counter {
            case .dropped(let eventIds):
                   updateMultiple(&dropped, for: Diagnostics.makeUnits(eventIds))
                   break
            
            /*case .http_error(
                let code
               ,let count):
                   updateSingle(&http_error, for: Diagnostics.http_error_codes[code] ?? "unknown", value: count)
                   break*/
            
            case .http_errors(let codes):
               updateMultiple(&http_errors, for: codes.map {  (Diagnostics.http_error_codes[$0.code] ?? "unknown", $0.count)  } )
               break
            
            
        
           /*case .status_code(
                let code,
                let count):
                   updateSingle(&http_error, for: "\(code)", value: count)
                   break*/
            
            case .status_codes(let codes):
               updateMultiple(&status_codes, for: codes.map {  ("\($0.code)", $0.count)  } )
               break
            
            
            case .received(let schemasList):
                   updateMultiple(&received, for: Diagnostics.makeUnits(schemasList) )
                   break
            case .retried(let eventIds):
                   updateMultiple(&retried, for: Diagnostics.makeUnits(eventIds))
                   break
            case .succeeded(let codes):
                   updateMultiple(&succeeded, for: codes.map {  ("\($0.code)", $0.count)  } )
                   break
            case .priority_log(let items):
                 updateMultiple(&priority_logs, for: Diagnostics.makeUnits(items.map {$0.rawValue}))
                   break
        }
    }
    
    /// Calculates a total for top N
    static func format<T: Hashable>(_ collection: [T:Int], total: Int, top: Int = 10) -> [T:Int]  {
                
        let topN = Dictionary(
            uniqueKeysWithValues: Array(
                collection.sorted { $0.value > $1.value }.prefix(top)
            )
        )
        
        return topN.merging( ["total" : total ]  as! [T:Int]) { $1 }
    }
    
    private func total<T: Hashable>(_ collection: [T:Int]) -> Int { collection.map { $0.value } .reduce(0,+) }
    
    /// Payload generation
    func payload(end: Date) ->  [String: Any] {
        
        let scTotal = total(status_codes)
        let heTotal = total(http_errors)
        
        return [
        "failed":[
            "status_code" : Diagnostics.format(status_codes, total: scTotal),
            "http_error"  : Diagnostics.format(http_errors, total: heTotal),
            "total" : scTotal + heTotal
        ],
            
        "start": "\(String(describing: start))",
        // "start": "\(start.epoch)",
        "end": "\(String(describing: end))",
        // "end": "\(end.epoch)",
        "queued": Diagnostics.format(queued, total: total(queued) ),
        "received": Diagnostics.format( [schema:1].merging(received) {$1}, total: _received.total + 1),
        // "received": Diagnostics.format(received, total: _received.total),
        "retried": Diagnostics.format(
            { var output = [String:Int]()
                for (key, value) in $0 { output[key] = value + 1 }
              return output
            }(retried), total: retried.count),
        // "retried": Diagnostics.format(retried, total: _retried.total),
        "succeeded": Diagnostics.format(succeeded, total: total(succeeded) ),
        "dropped": Diagnostics.format(dropped, total: _dropped.total),
        "priority_logs": Diagnostics.format(priority_logs, total: _priority_logs.total)
        ]
    }
    

    /// Deafault  0.0 is for business as usual. Other value good for test
    init(interval: TimeInterval = 0.0, schema: String = DIAGNOSTICS_SCHEMA, autoreset: Bool = true ) {
        
        // One-time assigment for schema
        self.schema = schema
        
        self.start = Date.now
        
        Task {
            for await _ in  await NotificationCenter.default.notifications(named: UIApplication.didReceiveMemoryWarningNotification) {
            
                await report(.priority_log([.lowMemoryCondition]))
            }
        }
        
        /// Task holds the Diagnostics loop
        Task {
            for await _ in  NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                
                // Closes the temporal bracket
                let end = Date.now
                
                let payload =  await self.payload(end: end)
                
                LIFT.tagEvent([
                    ccs.event_schema.key: schema,
                    ccs.event_name.key: try! schema.nameFromSchema,
                    ccs.event_payload.key: payload
                ]) { event in
                    
                    //event?.timestamp = 0 // highest priority
                
                    // Logging
                    let pretty = String(data: payload.jsonBytes(options: .prettyPrinted) ?? Data(), encoding: .utf8) ?? ""
                    
                    LIFT.SDK.logger.log(level: .info, "\nDiagnostics payload:\n\n \( pretty )")
                    
                    if interval > 0.0  { Task { await self.reset(end) } }
                    
                    else {
                        // Sound output during testing
                        Task { AudioServicesPlayAlertSound(1004) }
                    }
                }
            }
        }
        
        
        /// Manual control for
        if interval > 0.0 {
            Diagnostics.trigger = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
                _ in NotificationCenter.default.post(Notification(name: .NSCalendarDayChanged))
            }
        }
    }

    func reset(_ next: Date) {
        
        // Open the temporal bracket
        start = next

        dropped = [:]
        http_errors = [:]
        // queued is read-only
        received = [:]
        retried = [:]
        succeeded = [:]
    }
}

// Available to access private members during test

public extension Diagnostics {
    func pubReset(_ next: Date) { reset(next) }
    var allSent : Int { Diagnostics.format(succeeded, total: total(succeeded) )["total"] ?? 0 }
}
