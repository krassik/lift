//
//  Organizer.swift
//
//  Created by Krassi + AI
//

import Foundation
import CoreData
import os
import UIKit
import UIKit

public enum LIFT {

    public typealias Event = LIFTEvent // LIFT.Event == LIFTEvent from CoreData
    public typealias Attempt = LIFTAttempt // LIFT.Attempt == LIFTAttempt from CoreData
    
    typealias TopRecord = (key: String, value: ()->Any)
        
    public static var common: [String:Any] = [:]
    
    public static let ccsItems = {[
          ccs.account_id.key         : ""
         ,ccs.app_name.key           : ccs.app_name.value()        ?? ""
         ,ccs.app_ver.key            : ccs.app_ver.value()         ?? ""
         ,ccs.breadcrumb.key         : ""
         ,ccs.build.key              : ccs.build.value()           ?? ""
         ,ccs.carrier.key            : ccs.carrier.value()         ?? ""
         ,ccs.custom_payload.key     : [String:Any]()
         ,ccs.custom_schema.key      : ""
         ,ccs.device_id.key          : ""
         ,ccs.device_language.key    : ccs.device_language.value() ?? "en"
         ,ccs.device_make.key        : ccs.device_make.value
         ,ccs.device_model.key       : ccs.device_model.value()
         ,ccs.device_name.key        : ccs.device_name.value()
         ,ccs.device_timezone.key    : ccs.device_timezone.value()
         ,ccs.device_type.key        : ""
         ,ccs.event_name.key         : ""
         ,ccs.event_payload.key      : [String:Any]()
         ,ccs.event_schema.key       : ""
         ,ccs.event_type.key         : ""
         ,ccs.exo.key                : [String:Any]()
         ,ccs.library_ver.key        : LIFT_LIBRARY_VERSION
         ,ccs.network_type.key       : ccs.network_type.value()    ?? ""
         ,ccs.os_type.key            : ccs.os_type.value()
         ,ccs.os_ver.key             : ccs.os_ver.value()
         ,ccs.partner_id.key         : ""
         ,ccs.platform.key           : "ios"
         ,ccs.screen_flow.key        : [String]()
          ,ccs.session_id.key        : ccs.session_id.value()
         ,ccs.LIFT_uuid.key          : ccs.LIFT_uuid.value()       ?? ""
         ,ccs.trace_id.key           : ""
    ] as [String:Any] }
    
    public enum SDK {
        
        public static var isScripted = false
        public static var logLevel: Logger.SDKLogLevel = .info
        public static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "unknown", category: "LIFT.SDK")
        public static var policy: Policy?
        
        static var state = HostingApplicationState(isProtectedDataAvailable: true)

        public static var isInitialized: Bool {
            LIFT.Event.context != nil
            && policy != nil
            // Event capturing does not depend on Emitter
            // for simplicity, we shall watch to have both
        }
        
        static var session = Session(timeout: (TimeInterval(DEFAULT_SESSION_TIMEOUT.foreground), TimeInterval(DEFAULT_SESSION_TIMEOUT.background)))
        
        public static var headers: [String : String]? {
            get {
                (policy?.collector as? HTTPCollector)?.request.allHTTPHeaderFields
            }
            set {
                (policy?.collector as? HTTPCollector)?.request.allHTTPHeaderFields = newValue
            }
        }
        
        public static var diagnostics: Diagnostics?
        static var LIFT2Selection = [TopRecord]()
        static var common_schema: String? = nil
    }

    public static func initialize(
        logLevel: Logger.SDKLogLevel = .info,
        endpoint: String,
        headers: [String:String] = [:],
        // TODO: ensure this:
        // 0 <= min <= high && 0 <= low <= high  holds
        requestSendInterval: (min: TimeInterval, (low: TimeInterval, high: TimeInterval)) = DEFAULT_SEND_INTERVAL,
        batchLimit: Int = DEFAULT_MEMORY_LIMIT, // 100k
        nextBackoff: [Int:Int] = DEFAULT_BACKOFF_SEQUENCE,
        storageLimit: Int = DEFAULT_STORAGE_LIMIT,
        foreTime: TimeInterval = DEFAULT_FOREGROUND_TIMEOUT,
        backTime: TimeInterval = DEFAULT_BACKGROUND_TIMEOUT,
        // sessionTimeout: (foreground: Int, background: Int ) = DEFAULT_SESSION_TIMEOUT
        common_schema: String? = nil,
        autofill: [SchemaID] = DEFAULT_TOP,
        diagnostics:  TimeInterval = DEFAULT_DIAGNOSTICS_INTERVAL,
        tracing: Bool = DEFAULT_TRACING_FLAG
        // ,precheck: Double = DEFAULT_NETWORK_PRECHECK_PROBILITY
        ) { // p <= 0 is 0%, p >= 1 is 100%
            
        guard !SDK.isInitialized else {
            SDK.logger.log(level: .error, "Already intialized.")
            return
        }
            
        // start network monitoring
        NetworkInfo.startMonitoring()
    
        SDK.logLevel = logLevel
 
        SDK.session = Session(timeout: (foreTime, backTime))
        // SDK.session = Session(timeout: (TimeInterval( sessionTimeout.foreground ), TimeInterval(sessionTimeout.background)))
            
        SDK.LIMIT.memory  = {
            switch $0 {
             case let x where x > MAX_MEMORY_LIMIT:
                SDK.logger.log(level: .info, "\(MAX_MEMORY_LIMIT) replaces invalid batchLimit configuration \(x)" )
                return MAX_MEMORY_LIMIT
             case let x where x < 0:
                SDK.logger.log(level: .info, "\(DEFAULT_MEMORY_LIMIT) replaces invalid batchLimit configuration \(x)" )
                return DEFAULT_MEMORY_LIMIT
             default:
                return $0
            }
        }(batchLimit)
            
        SDK.LIMIT.storage = storageLimit
            
        if SDK.isScripted {
            ValueTransformer.setValueTransformer(
                EffectValueTransformer(),
                forName: NSValueTransformerName("EffectValueTransformer")
            )
        }
        

        let container: NSPersistentContainer?  =  {
    
            guard let modelURL = LIFT.SDK.Resources.bundle.url(forResource: DEFAULT_BUFFER_NAME, withExtension:"momd") else {
                SDK.logger.log(level: .warn, "Error loading model from bundle")
                return nil
            }
            guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
                SDK.logger.log(level: .warn, "Error initializing managed object model from: \(modelURL)")
                return nil
            }
            let container = NSPersistentContainer(name: DEFAULT_BUFFER_NAME, managedObjectModel: mom)

            
            if SDK.LIMIT.storage <= 0 {
                let description = NSPersistentStoreDescription()
                (description.type, description.shouldAddStoreAsynchronously) = (NSInMemoryStoreType, false)
                container.persistentStoreDescriptions = [description]
            }
                
            container.loadPersistentStores { description, err in
                if let error = err {
                    SDK.logger.log(level: .warn, "Error loading \(description.type): \(error.localizedDescription)")
                } else {
                    SDK.logger.log(level: .info, "\(description.type) ready")
                }
            }

            return container
        }()
            
        LIFT.Event.context = container?.newBackgroundContext()
        
        guard LIFT.Event.context != nil else {
            SDK.logger.log(level: .error, "CoreData not available; The SDK cannot initialize.")
            return
        }
        
        if diagnostics >= 0.0 {
            SDK.diagnostics = Diagnostics(interval: diagnostics)  // seconds
            SDK.logger.log("Diagnostics(interval: \(diagnostics)) is enabled")
        }
        
        // Calculate the average message size in the buffer
        // After restart AMS must be reprimed
        LIFT.Event.context?.performAndWait { LIFT.Event.setBufferAverage() }
            
        // min = 0 will stop event loop if one has otherwise been running
        SDK.policy?.requestSendInterval = (0,(0,0))
        SDK.policy = nil // ... and reclaim the memory
            
        SDK.policy = Policy(
            collector: endpoint.epType == .request
                  ? HTTPCollector(endpoint, headers: headers, tracing: tracing)
                  : SocketCollector(endpoint, headers: headers, tracing: tracing)
                ,
            batchLimit: batchLimit,
            requestSendInterval: requestSendInterval, // Notes the original value
            nextBKF: nextBackoff
            //,precheck: precheck
        )
            
        SDK.common_schema = common_schema
            
        let permanent_items = [
             (tag: LIFT.common_1, item: (cmn.event_source.key, cmn.event_source.value) )
            ,(tag: LIFT.common_1, item: (cmn.event_source_version.key, cmn.event_source_version.value) )
            //,(tag: LIFT.common_1, item: (csc.common_schema.key  , csc.common_schema.value) )
            //,(tag: LIFT.common_1, item: (csc.env.key            , csc.env.value) )
            //,(tag: LIFT.common_1, item: (csc.event_name.key     , csc.event_name.value) )
            //,(tag: LIFT.common_1, item: (csc.product_name.key, csc.product_name.value) )
            //,(tag: LIFT.common_1, item: (csc.product_version.key, csc.product_version.value) )
            
            ,(tag: LIFT.logger_1, item: (logger.name.key   , logger.name.value) )
            ,(tag: LIFT.logger_1, item: (logger.version.key, logger.version.value) )
            
        ] as [(tag: String, item: (String, () -> Any))]

        let optional_items = [
            
            // (tag: LIFT.cet_1, item: (cet.access_payload.key    , cet.access_payload.value) )
            //,(tag: LIFT.cet_1, item: (cet.access_schema.key     , cet.access_schema.value) )
            
            //,(tag: LIFT.device_1, item: (device.name.key      , device.device_name.value) )
             (tag: LIFT.device_1, item: (device.model.key, device.model.value) )
            ,(tag: LIFT.device_1, item: (device.type.key, device.type.value) )
            ,(tag: LIFT.device_1, item: (device.os_name.key, device.os_name.value) )
            ,(tag: LIFT.device_1, item: (device.os_version.key, device.os_version.value) )
            ,(tag: LIFT.device_1, item: (device.timezone.key  , device.timezone.value ) )
            ,(tag: LIFT.device_1, item: (device.manufacturer.key, device.manufacturer.value) )
            ,(tag: LIFT.device_1, item: (device.platform.key, device.platform.value) )
            
            // ,(tag: LIFT.session_1, item: (session.device_session_id.key , session.device_session_id.value ) )
 
            //,(tag: LIFT.sat_1, item: (sat.authenticated.key, sat.authenticated.value) )
             
            //,(tag: LIFT.xbo_1, item: (xbo.activated.key     , xbo.activated.value) )
            // ,(tag: LIFT.xbo_1, item: (xbo.partner_id.key    , xbo.partner_id.value) )
            // ,(tag: LIFT.xbo_1, item: (xbo.xbo_account_id.key, xbo.xbo_account_id.value) )
            // ,(tag: LIFT.xbo_1", item: (xbo.xbo_device_id.key , xbo.xbo_device_id.value) )
        ].filter { autofill.contains($0.tag)} as [(tag: String, item: (String, () -> Any))]
            
        SDK.LIFT2Selection = (permanent_items + optional_items)
               .map { $0.item } as [(key: String, value: () -> Any)]

        SDK.policy?.resume() // starts the event loop
    }
}

extension LIFT.Event {
    
    // Most general constructor
    @discardableResult
    public convenience init?(_ instanceItems:() -> [String:Any]) {
        
        // Can check this before anything else to avoid unecessary computation
        
        var bytesInStorage: Int64 = 0
        
        LIFT.Event.context?.performAndWait {
            bytesInStorage = LIFT.SDK.bytesInStorage
        }
        
        guard bytesInStorage
                // + Int64(LIFT.SDK.LIMIT.event)
                + Int64(LIFT.Event.averageSize)
                // Conservative vs liberal option here
                < (LIFT.SDK.LIMIT.storage > 0 ? LIFT.SDK.LIMIT.storage : LIFT.SDK.LIMIT.memory )  else {
            
            LIFT.SDK.logger.log(level: .error, "\(LIFT.Event.averageSize) bytes on average + \(LIFT.SDK.bytesInStorage) in current storage exceed \(LIFT.SDK.LIMIT.storage) of storage limit. Dropping")
            return nil // construction aborted here
        }
       
        self.init(LIFTEvent.self) // If no buffer was initilized,  contruction will stop here
        
        let items = instanceItems()
        self.schema = (items[ccs.event_schema.key] as? String) ?? "unknown"
        
        let common = LIFT.common.filter {
            
            key, value in
        
            // Next is list of event type that cannot be common
            if [ccs.event_schema.key
               ,ccs.event_name.key
               ,ccs.event_payload.key
            ].contains(key) {
                LIFT.SDK.logger.log(level: .warn, "Ignoring \(key) = \(value) in common")
                return false
            }
            // else
            return true
        }
        
        // let sessionID = LIFT.SDK.session.id(after: self.timestamp)
        
        // Precedence combiner
        let event =
            items
            .merging(common)                 {$1}
            .merging(
                [ccs.event_id.key : self.id!.uuidString
                ,ccs.timestamp.key: self.timestamp
            ])                             {$1}
        
        guard let bytes = event.jsonBytes() else {
            LIFT.SDK.logger.log(level:.warn,"Event \(event[ccs.event_name.key] ?? "UNKNOWN") will be dropped due to JSON encoding failure")
            return nil
        }
        
        let payloadSize = bytes.count
        
        guard payloadSize <= min(LIFT.SDK.LIMIT.event, LIFT.SDK.LIMIT.memory) else {
            log(level: .error, "\(payloadSize) bytes in payload exceed memory limit \(LIFT.SDK.LIMIT.memory) bytes or \(LIFT.SDK.LIMIT.event) bytes for event. Dropped")
            // Without next line 0-sized events may show up in the system
            LIFT.Event.context?.delete(self)
            return nil
        }
        
        self.payload = bytes
        // Payload is not expected to mutate
        // size can be recorded at this point
        self.size = Int32(payloadSize)
    }
}

extension LIFT {
    
    public static func tagEvent(_ items: [String: Any], _ customize: @escaping ( LIFTEvent? ) -> Void = { $0?.save() }) {
        
        guard let context = LIFT.Event.context else {
            let msg = "Initialization must preceed capture."
            LIFT.SDK.logger.log(level: .error, msg )
            #if DEBUG
              assertionFailure(msg)
            #endif
            return
        }
       
       let version_items =
        ( SDK.common_schema != nil
           ? ["common_schema" : SDK.common_schema! ].merging( Dictionary(uniqueKeysWithValues: SDK.LIFT2Selection.map { ($0.key, $0.value()) } )) {$1}
         : LIFT.ccsItems()).merging(items) {$1}
        
        guard LIFT.SDK.state.isProtectedDataAvailable else {
            let id = items["event_name"] as? String ?? "unknown"
            LIFT.SDK.logger.log(level: .info, "\(id) event was skipped because the device was locked." )
            return
        }
        context.perform { customize( Event { version_items } ) }
    }
    
    public static func tagEvent(_ schema: String, _ payload: [String:Any]) {
        
        guard let name = try? schema.nameFromSchema else {
            SDK.logger.log(level: .warn, "\(schema) string invalid")
            return
        }
        
        LIFT.tagEvent(
            [ccs.event_name.key    : name
            ,ccs.event_schema.key  : schema
            ,ccs.event_payload.key : payload
            ]
        )
    }
    
    public static func tagUnstructuredEvent(_ name: String, _ payload: [String:Any]) {
        
        LIFT.tagEvent(
           [ccs.event_name.key    : name
           ,ccs.event_schema.key  : ""
           ,ccs.event_payload.key : payload
           ]
        )
    }
}


public
extension Dictionary<String, Any> {
    
    func tagEvent() {
        
        guard let context = LIFTEvent.context,
              let entity = NSEntityDescription.entity(forEntityName: "LIFTEvent", in: context)
        else {
            // TODO: log
            return
        }
        
        let event =  LIFTEvent(entity: entity, insertInto: context)
        
        guard let bytes = self.jsonBytes() else {
            LIFT.SDK.logger.log(level:.warn,"Event \(self[ccs.event_name.key] ?? "UNKNOWN") will be dropped due to JSON encoding failure")
            return
        }
        
        let payloadSize = bytes.count
        
        event.payload = bytes
        // Payload is not expected to mutate
        // size can be recorded at this point
        event.size = Int32(payloadSize)
        
        event.save()
    }
}

