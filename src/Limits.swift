//
//  Limits.swift
//
//  Created by Krassi + AI
//

import Foundation
import CoreData

extension LIFT.SDK {
    
    public enum LIMIT {
        public static var event = DEFAULT_EVENT_LIMIT
        public static var memory = DEFAULT_MEMORY_LIMIT
        public static var storage = DEFAULT_STORAGE_LIMIT
    }
    
    private static var _lastBytesInStorage: Int64 = 0
    
    public static var lastBytesInStorage: Int64 { _lastBytesInStorage }
    
    // Calculates the CoreData alloction on disk
    // by querying the files system
    public static var bytesInStorage: Int64 {
        
        guard let store = LIFTEvent.context?
            .persistentStoreCoordinator?
            .persistentStores.first else {
            return 0
        }
        
        if store.type == NSInMemoryStoreType {
            // NOTE: This is alternative to aggregation due to bug
            // https://developer.apple.com/forums/thread/43757
            _lastBytesInStorage = Int64(LIFT.Event.sum)
            return lastBytesInStorage
        }
        
        guard let storePath = LIFTEvent.context?
            .persistentStoreCoordinator?
            .persistentStores.first?
            .url?.path else {
            return 0
        }
        
        _lastBytesInStorage = ALL_BUFFER_FILES.map {
            (try? FileManager.default.attributesOfItem(
                atPath: storePath.appending("\($0)")
              )[.size]) as? Int64 ?? Int64(0)
        }
        .reduce(Int64(0),+)
        
        return lastBytesInStorage
    }
    
    public static func forceToLimit<T>( _ range: ClosedRange<T>, value: T, note: String = "") -> T {
        switch value {
            case let x where x > range.upperBound:
               LIFT.SDK.logger.log(level: .warn, "Forcing \(note) size \(value) to \(range.upperBound) upper limit")
               return range.upperBound
            case let x where x < range.lowerBound:
               LIFT.SDK.logger.log(level: .warn, "Forcing \(note) size \(value) to \(range.lowerBound) lower limit")
               return range.lowerBound
            default: return value
        }
    }
}
