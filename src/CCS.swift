//
//  CCS.swift
//
//  Created by Krassi + AI
//
import UIKit

// The comprehensive list of CCS attibutes along the retriever where one exists

public enum ccs {
    public static let account_id          = (key: "account_id", "")
    public static let app_name            = (key: "app_name",        value: { Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String })
    public static let app_ver             = (key: "app_ver",         value: { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String })
    public static let breadcrumb          = (key: "breadcrumb", "")
    public static let build               = (key: "build",           value: { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String })
    public static let carrier             = (key: "carrier",         value: { NetworkInfo.carrierName })
    public static let custom_payload      = (key: "custom_payload", [String:Any]())
    public static let custom_schema       = (key: "custom_schema", "")
    public static let device_id           = (key: "device_id", "")
    public static let device_language     = (key: "device_language", value: { Locale.current.languageCode })
    public static let device_make         = (key: "device_make",     value: MANUFACTURER )
    // public static let device_model        = (key: "device_model",    value: { UIDevice.current.model })
    public static let device_model        = (key: "device_model",    value: LIFT.getDeviceModel )
    public static let device_name         = (key: "device_name",     value: { UIDevice.current.name })
    public static let device_timezone     = (key: "device_timezone", value: { TimeZone.current.secondsFromGMT() * 1000 })
    public static let device_type         = (key: "device_type", "")
    public static let event_id            = (key: "event_id", "")
    public static let event_name          = (key: "event_name", "")
    public static let event_payload       = (key: "event_payload", [String:Any]())
    public static let event_schema        = (key: "event_schema", "")
    public static let event_type          = (key: "event_type", "")
    public static let exo                 = (key: "exo", [String:Any]())

    public static let library_ver         = (key: "library_ver",     value: "")
    public static let network_type        = (key: "network_type",    value: { NetworkInfo.networkType })
    public static let os_type             = (key: "os_type",         value: { UIDevice.current.systemName.lowercased() })
    public static let os_ver              = (key: "os_ver",          value: { UIDevice.current.systemVersion }) // ProcessInfo().operatingSystemVersionString
    public static let partner_id          = (key: "partner_id", "")
    public static let platform            = (key: "platform", DEVICE_PLATFORM)

    public static let screen_flow         = (key: "screen_flow", [String]())

    public static let session_id          = (key: "session_id",      value: { LIFT.SDK.session.id(after: Date.now.epoch) })
    public static let LIFT_uuid           = (key: "lift_uuid",       value: { UIDevice.current.identifierForVendor?.uuidString })
    public static let timestamp           = (key: "timestamp", 0)
    public static let trace_id            = (key: "trace_id", "")

}

