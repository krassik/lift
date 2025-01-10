//
//  Deafults.swift
//  
//
//  Created by Krassi + AI
//

import Foundation

public let MANUFACTURER = "Apple"
public let PLATFORM = "ios"
public let LOGGER_NAME = "dift sdk ios"
public let LOGGER_VERSION = "4.0.0"
public let LIFT_LIBRARY_VERSION = "LIFT SDK \(LOGGER_VERSION)"
public let DEFAULT_SEND_INTERVAL =
      (min: TimeInterval(60), variation: (low: TimeInterval(0),high: TimeInterval(0)))
public let DEFAULT_MAX_RETRIES = 4
public let DEFAULT_BACKOFF_SEQUENCE = [0:300,300:1500,1500:7500,7500:7500]
public let DEFAULT_EVENT_LIMIT   =       1 * 1 * 512 * 1024 // 1/2 MB
public let EVENT_SIZE_RANGE      =   0...1 * 1 * 512 * 1024 // 1/2 MB
public let DEFAULT_MEMORY_LIMIT  =       1 * 1 * 100 * 1024
public let MAX_MEMORY_LIMIT      =       1 * 2 * 512 * 1024
public let MEMORY_SIZE_RANGE     =   0...1 * 2 * 512 * 1024
public let DEFAULT_STORAGE_LIMIT =      10 * 2 * 512 * 1024 // 10MB
public let STORAGE_SIZE_RANGE    =  0...10 * 2 * 512 * 1024
public let ALL_BUFFER_FILES = ["","-wal","-shm"]
public let DEFAULT_FOREGROUND_TIMEOUT = TimeInterval(30 * 60) // = 30 min
public let DEFAULT_BACKGROUND_TIMEOUT = TimeInterval(30 * 60)
public let DEFAULT_SESSION_TIMEOUT = (foreground: 30, background: 30 ) // 30 min
public let DEFAULT_NETWORK_PRECHECK_PROBILITY = 1.0
public let RESPONSE_LIMIT_LOG = 1024 // bytes
public let DIAGNOSTICS_SCHEMA = "lift/diagnostics/1"
public let DEFAULT_DIAGNOSTICS_INTERVAL = TimeInterval(24 * 60 * 60)  // 24h
public let DEFAULT_TRACING_FLAG = true
public let DEFAULT_TOP: [String] = [] // ["LIFT/common/1","LIFT/device/1"]


#if os(iOS)
    public let DEVICE_PLATFORM = "iOS"
#elseif os(tvOS)
    public let DEVICE_PLATFORM = "tvOS"
#endif

public let DEFAULT_BUFFER_NAME = "EventDM2"
