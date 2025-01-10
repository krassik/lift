//
//  Logger.swift
//  
//  Created by Krassi + AI
//

import Foundation
import os

// Control per type 

extension LIFT.Event {
    func log(fileID: String = #fileID, line: Int = #line, level: Logger.SDKLogLevel = .debug, _ message: String) {
        let message = message.appending(" event (Id: \(id?.uuidString.prefix(8) ?? "event_id"), Name: \(payload?.jsonPayload?["event_name"] ?? "event_name"), Size: \(size) bytes)")
        LIFT.SDK.logger.log(fileID: fileID, line: line, level: level, message)
    }
}

extension Batch {
    
    static func describe(events: [LIFTEvent]) -> String {
        return "[\(events.map { "(".appending(($0.id?.uuidString ?? "event_id").prefix(8-4)).appending(", \($0.retryCount), \($0.size) bytes)") }.joined(separator:","))]"
    }
    
    
    func log(fileID: String = #fileID, line: Int = #line, level: Logger.SDKLogLevel = .info, _ message: String) {
        let message = message.appending(" batch \(Batch.describe(events: events))")
        LIFT.SDK.logger.log(fileID: fileID, line: line, level: level, message)
    }
}

extension HTTPCollector {
    func log(fileID: String = #fileID, line: Int = #line, level: Logger.SDKLogLevel = .info, _ message: String) {
        LIFT.SDK.logger.log(fileID: fileID, line: line, level: level, message)
    }
}

extension Policy {
    func log(fileID: String = #fileID, line: Int = #line, level: Logger.SDKLogLevel = .info, _ message: String) {
        // let message = message.appending(" BACKOFF:\(bkfInterval)")
        LIFT.SDK.logger.log(fileID: fileID, line: line, level: level, message)
    }
}

extension Session {
    func log(fileID: String = #fileID, line: Int = #line, level: Logger.SDKLogLevel = .info, _ message: String) {
        LIFT.SDK.logger.log(fileID: fileID, line: line, level: level, message)
    }
}

/*
extension Diagnostics {
    func log(fileID: String = #fileID, line: Int = #line, level: Logger.SDKLogLevel = .info, _ message: String = "" ) {
        LIFT.SDK.logger.log(fileID: fileID, line: line, level: level,
                            message.appending("\nDiagnostics payload:\n\n \( self.description )")
        )
    }
    
    var description: String {
        String(data: payload(end: Date.now).jsonBytes(options: .prettyPrinted) ?? Data(), encoding: .utf8) ?? ""
    }
}
*/
extension Logger {
    
    public enum SDKLogLevel: UInt8 {
        case debug, info, warn, error, none
        func convert() -> OSLogType {
            switch self {
            case .debug, .info, .warn, .error, .none:
            return .default
            }
        }
        
        static func >=(lhs:SDKLogLevel, rhs:SDKLogLevel) -> Bool {
            return lhs.rawValue >= rhs.rawValue
        }
    }
    
    func log(fileID: String = #fileID, line: Int = #line, level: SDKLogLevel = .info, _ message: String) {
        
        guard level >= LIFT.SDK.logLevel else { return }
        
        let stamp: String = {
            let df = DateFormatter()
            df.dateFormat = "y-MM-dd H:mm:ss,SSS"
            return df.string(from: Date())
        }()
        
        let fileName = fileID.split(separator: "/")[1].split(separator: ".").first ?? "unknown"
        self.log(level: level.convert(), "\(stamp)\t\([0:"DEBUG",1:"INFO ",2:"WARN ",3:"ERROR"][level.rawValue]!)\t\(fileName):\(line)\t\t\t\t \(message)")
    }
}
