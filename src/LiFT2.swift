//
//  LiFT.swift
//  
//
//  Created by Krassi + AI
//

import UIKit


public
extension LIFT {
    
    typealias SchemaID = String
    static let cet_1 = "lift/cet/1"
    static let common_1 = "lift/common/1"
    static let device_1 = "lift/device/1"
    static let logger_1 = "lift/logger/1"
    static let sat_1 = "lift/sat/1"
    static let xbo_1 = "lift/xbo/1"
    static let session_1 = "entos/session/1" // TODO: clarify this
    
   
    enum session {
        public static let device_session_id    = (key: "device_session_id",  value: { LIFT.SDK.session.id(after: Date.now.epoch) } )
    }
    
    enum cet {
        public static let access_payload       = (key: "access_payload",     value: {[
            
                       "durable_app_id"              : "",
                       "capabilities_exclusion_tags" : [String:Any]()
                    ] as [String:Any] })
        
        public static let access_schema        = (key: "access_schema",      value: {""} )
    }
    
    // The comprehensive list of CSC attibutes along the retriever where one exists
    
    enum cmn {
        //public static let app_name             = (key: "app_name",           value: { Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String } )
        
        public static let event_source             = (key: "event_source",           value: { Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String } )
        
        
        
        // public static let app_version          = (key: "app_version",        value: { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String } )
        
        public static let event_source_version          = (key: "event_source_version",        value: { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String } )
        
        //public static let common_schema        = (key: "common_schema",      value: {""} )
        
        public static let env                  = (key: "env",                value: {""} )
        
        // public static let event_id             = (key: "event_id",           value: {""} )
        public static let event_name           = (key: "event_name",         value: {""} )
        public static let event_payload        = (key: "event_payload",      value: { [String:Any]() } )
        public static let event_schema         = (key: "event_schema",       value: {""} )
        
        public static let product_name         = (key: "product_name",       value: {""} )
        public static let product_version      = (key: "product_version",    value: {""} )
        
        // public static let session_id           = (key: "session_id",         value: {""} )
        // public static let LIFT_uuid            = (key: "LIFT_uuid",          value: { UIDevice.current.identifierForVendor?.uuidString } )
        // public static let timestamp            = (key: "timestamp",          value: {0}  )
        // public static let trace_id             = (key: "trace_id",           value: {""} )
        
    }
    
    enum device {
        // public static let name          = (key: "device_name",         value: { UIDevice.current.name } )
        public static let model         = (key: "device_model",   value: LIFT.getDeviceModel )
        
        public static let type          = (key: "device_type",         value:{
            ["Phone","Pad","TV","CarPlay","Mac","Headset"][UIDevice().userInterfaceIdiom.rawValue]
        } )

        public static let os_name       = (key: "device_os_name",             value: { UIDevice.current.systemName.lowercased() } )
        public static let os_version    = (key: "device_os_version",              value: { UIDevice.current.systemVersion } ) // ProcessInfo().operatingSystemVersionString
        public static let timezone      = (key: "device_timezone",     value: { TimeZone.current.secondsFromGMT() * 1000 } )
        
        public static let manufacturer  = (key: "device_manufacturer", value:{ MANUFACTURER } )
        public static let platform  = (key: "platform", value:{ PLATFORM } )
        
    }
    
    enum logger {
        public static let name          = (key: "logger_name",         value:{ LOGGER_NAME } )
        public static let version       = (key: "logger_version",      value:{ LOGGER_VERSION } )
    }
    
    enum sat {
        public static let authenticated        = (key: "authenticated",       value: {false} ) // opt
    }
    
    enum xbo {
        public static let activated            = (key: "activated",           value: {false} ) // opt
        public static let partner_id           = (key: "partner_id",          value: {""} )
        public static let account_id       = (key: "xbo_account_id",      value: {""} )
        public static let device_id        = (key: "xbo_device_id",       value: {""} )
    }
    
    /* EntOS items
    enum entao {
        public static let account_type         = (key: "account_type", "" )
        public static let country              = (key: "country", "" )
        public static let detail_type          = (key: "detail_type", "" )
        public static let `operator`           = (key: "operator", "" )
        public static let region               = (key: "region", "" )
    }
    
    enum entdo {
        public static let coam                 = (key: "coam", value: false)
        public static let device_mac_address   = (key: "device_mac_address", "")
        public static let device_serial_number = (key: "device_serial_number", "")
        public static let jv_agent             = (key: "jv_agent", "")
        public static let proposition          = (key: "proposition", "")
        public static let retailer             = (key: "retailer", "")
    }
    */
}
