//
//  Policy.swift
//
//  Created by Krassi + AI
//

import Foundation
import CoreData
import os
import UIKit

public class Policy {
    
    public enum Action {
        case doNotRetry
        case retryUpToMax
        // case retryIndefinitely
    }

    private var senderTask: Task<Void,Never>? = nil

    let collector: Collector
    var batchLimit: Int
    var bkfInterval = 0
    var retries: Int
    var nextBKF: [Int:Int]
    // var precheck_probability: Double
    private let originalSendInterval: (min: TimeInterval, variation: (low:TimeInterval, high:TimeInterval))
    var requestSendInterval: (min: TimeInterval, variation: (low:TimeInterval, high:TimeInterval)) 
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public init(
          collector: Collector,
          batchLimit: Int = DEFAULT_MEMORY_LIMIT,
          requestSendInterval: (TimeInterval, (TimeInterval,TimeInterval)),
          retries: Int = DEFAULT_MAX_RETRIES,
          nextBKF: [Int:Int] = DEFAULT_BACKOFF_SEQUENCE)
          //,precheck: Double = DEFAULT_NETWORK_PRECHECK_PROBILITY)
    {
        self.collector = collector
        self.batchLimit = batchLimit
        self.originalSendInterval = requestSendInterval
        self.requestSendInterval = requestSendInterval
        self.retries = retries
        self.nextBKF = nextBKF
        // self.precheck_probability = precheck
        
        NotificationCenter.default.addObserver(
            forName:  UIApplication.didBecomeActiveNotification,
            object: nil, queue: nil, using: resume // coming from background
        )
    }

    // Formats a batch that fits the memory limit
    private func trimToLimit(_ allEvents: [LIFTEvent]? ) -> [LIFTEvent]? {
        
        guard let events = allEvents else {
            return nil
        }
        
        if events.isEmpty {
            return []
        }
        
        let count = events.count
        
        if count == 1 {
            return events
        }
        
        var batchSize = events.map { $0.size }.reduce(0, +)
        var last = count - 1
        
        while (batchSize > LIFT.SDK.LIMIT.memory) {
            batchSize -= events[last].size; last -= 1 //  <- the trimmer
        }
      
        return Array(events[0...last])
    }
    
    func send() async {
        
        guard let context = LIFTEvent.context else { return }
        
        let size = LIFT.Event.averageSize
        // avg size = 0 corresponds to empty buffer
        guard size > 0 else { return }
        
        let request = LIFTEvent.fetchRequest()
        
        request.fetchLimit = batchLimit / size
        request.sortDescriptors = [ NSSortDescriptor(key: "timestamp", ascending: true) ]
        request.propertiesToFetch = ["size"]
        
        var events: [LIFTEvent] = []
        
        context.performAndWait {
            // without trim step = faster
            events = trimToLimit(try? context.fetch(request) as [LIFTEvent]) ?? []
        }
        
        guard !events.isEmpty else {
            log(level: .info, "Empty buffer")
            requestSendInterval = originalSendInterval
            NotificationCenter.default.post(Notification(name: LIFT.notification(.emptyBuffer) ) ) 
            return
        }
        
        let batch = Batch(events: events) // Creates batch from db

        let count = batch.events.count
        context.performAndWait {
            batch.log(level:.info, "Fetched \( count ) event\(count != 1 ? "s" : "") in")
            batch.updateCounters(+1)
        }
        
        // Post
        switch await collector.post( batch ) {
         case .doNotRetry:
            
            context.performAndWait {
                batch.delete()
                // NotificationCenter.default.post(Notification(name: LIFT.notification(.sentEvents)))
            }
            requestSendInterval = (1,(0,0)) // or (1, originalSendInterval.variation ) ?
            bkfInterval = 0
        
         case .retryUpToMax:
            context.performAndWait {
                batch.log(level:.info, "failed; will retry")
                batch.delete(after: self.retries )
            }
            requestSendInterval = originalSendInterval
            
            guard let nextInterval = nextBKF[bkfInterval] else {
                LIFT.SDK.logger.log(level: .warn, "BKF plan \(nextBKF) misses [\(bkfInterval):?]. Value \(bkfInterval) will remain until next inspection.")
                // keep where the value is and move on
                return
            }
            bkfInterval = nextInterval
         /*
         case .retryIndefinitely:
            batch.log(level:.info, "send failed; will reattempt send")
            batch.updateCounters(-1)
            bkfInterval = nextBKF[bkfInterval]!
          */
        }
    }
    
    
    @objc func resume(_: Notification? = nil) {
        guard senderTask?.isCancelled ?? true else { return }
        
        requestSendInterval = originalSendInterval
         
        senderTask = Task {
            log(level:.info, "Starting event-send loop with config next backoff: \(bkfInterval), batch size: \(batchLimit), interval: \(requestSendInterval)s, retry limit:\(retries)")
            while await UIApplication.shared.applicationState == .active  && requestSendInterval.min > 0 {
                
                let interval = max(
                    requestSendInterval.min
                    + TimeInterval.random(in:
                          requestSendInterval.variation.low...requestSendInterval.variation.high
                      ),
                    TimeInterval(bkfInterval)
                )
                
                log(level:.debug, "Event-send loop sleeping for \(interval)s")
                try? await Task.sleep(nanoseconds: UInt64( interval ) * 1_000_000_000)
                
                guard  // p <= 0 is 0%, p >= 1 is 100%
                       // Double.random(in: 0..<1) < min(max(0.0, precheck_probability), 1.0),
                    NetworkInfo.isConnected else {
                    log(level:.debug,"Skips sending; Network not available")
                    continue
                }
                
                
                log(level:.debug,"Event-send loop sending events after sleeping for \(interval)s")
                await send()
                
                LIFT.SDK.logger.log(
                    level: LIFT.SDK.lastBytesInStorage < LIFT.SDK.LIMIT.storage / 2 ? .debug : .info,
                    String(format: "%.2f MB in buffer", Double(LIFT.SDK.lastBytesInStorage) / (1024 * 1024))
                )
          
            }
            senderTask?.cancel()
            senderTask = nil
            log(level:.debug,"Event-send loop finished")
        }
    }
}

// Available to access private members during test

public extension Policy {
    var pubCollector: Collector { collector }
}
