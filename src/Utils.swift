//
//  Utilities.swift
//
//  Created by Krassi + AI
//

#if os(iOS)
import CoreTelephony
#endif
import Network
import Foundation
import CoreData
import UIKit

public let deviceModels = [
   "iPhone1,1" : "iPhone"
  ,"iPhone1,2" : "iPhone 3G"
  ,"iPhone2,1" : "iPhone 3GS"
  ,"iPhone3,1" : "iPhone 4"                      // (GSM)
  ,"iPhone3,2" : "iPhone 4"                      // (GSM Rev A)
  ,"iPhone3,3" : "iPhone 4"                      // (CDMA/Verizon/Sprint)
  ,"iPhone4,1" : "iPhone 4S"
  ,"iPhone5,1" : "iPhone 5"                      // (model A1428, AT&T/Canada)
  ,"iPhone5,2" : "iPhone 5"                      // (model A1429)" // everything else)
  ,"iPhone5,3" : "iPhone 5c"                     // (model A1456, A1532 | GSM)
  ,"iPhone5,4" : "iPhone 5c"                     // (model A1507, A1516, A1526 (China), A1529 | Global)
  ,"iPhone6,1" : "iPhone 5s"                     // (model A1433, A1533 | GSM)
  ,"iPhone6,2" : "iPhone 5s"                     // (model A1457, A1518, A1528 (China), A1530 | Global)
  ,"iPhone7,1" : "iPhone 6 Plus"
  ,"iPhone7,2" : "iPhone 6"
  ,"iPhone8,1" : "iPhone 6S"
  ,"iPhone8,2" : "iPhone 6S Plus"
  ,"iPhone8,4" : "iPhone SE"
  ,"iPhone9,1" : "iPhone 7"                      // (CDMA)
  ,"iPhone9,3" : "iPhone 7"                      // (GSM)
  ,"iPhone9,2" : "iPhone 7 Plus"                 // (CDMA)
  ,"iPhone9,4" : "iPhone 7 Plus"                 // (GSM)
  ,"iPhone10,1": "iPhone 8"                      // (CDMA)
  ,"iPhone10,4": "iPhone 8"                      // (GSM)
  ,"iPhone10,2": "iPhone 8 Plus"                 // (CDMA)
  ,"iPhone10,5": "iPhone 8 Plus"                 // (GSM)
  ,"iPhone10,3": "iPhone X"                      // (CDMA)
  ,"iPhone10,6": "iPhone X"                      // (GSM)
  ,"iPhone11,2": "iPhone XS"
  ,"iPhone11,4": "iPhone XS Max"
  ,"iPhone11,6": "iPhone XS Max"                 // China
  ,"iPhone11,8": "iPhone XR"
  ,"iPhone12,1": "iPhone 11"
  ,"iPhone12,3": "iPhone 11 Pro"
  ,"iPhone12,5": "iPhone 11 Pro Max"
  ,"iPhone12,8": "iPhone SE (2nd Gen)"
  //iPad 1
  ,"iPad1,1"   : "iPad - Wifi"                   // (model A1219)
  ,"iPad1,2"   : "iPad - Wifi + Cellular"        // (model A1337)
  //iPad 2
  ,"iPad2,1"   : "iPad2 - Wifi"                  // (model A1395)
  ,"iPad2,2"   : "iPad2"                         // - GSM (model A1396)
  ,"iPad2,3"   : "iPad2 - 3G"                    // (model A1397)
  ,"iPad2,4"   : "iPad2 - Wifi"                  // (model A1395)
  // iPad Mini
  ,"iPad2,5"   : "iPad Mini - Wifi"              // (model A1432)
  ,"iPad2,6"   : "iPad Mini - Wifi + Cellular"   // (model A1454)
  ,"iPad2,7"   : "iPad Mini - Wifi + Cellular"   // (model A1455)
  //iPad 3
  ,"iPad3,1"   : "iPad3 - Wifi"                  // (model A1416)
  ,"iPad3,2"   : "iPad3 - Wifi + Cellular"       // (model A1403)
  ,"iPad3,3"   : "iPad3 - Wifi + Cellular"       // (model A1430)
  //iPad 4
  ,"iPad3,4"   : "iPad4 - Wifi"                  // (model A1458)
  ,"iPad3,5"   : "iPad4 - Wifi + Cellular"       // (model A1459)
  ,"iPad3,6"   : "iPad4 - Wifi + Cellular"       // (model A1460)
  //iPad AIR
  ,"iPad4,1"   : "iPad Air - Wifi"               // (model A1474)
  ,"iPad4,2"   : "iPad Air - Wifi + Cellular"    // (model A1475)
  ,"iPad4,3"   : "iPad Air - Wifi + Cellular"    // (model A1476)
  // iPad Mini 2
  ,"iPad4,4"   : "iPad Mini 2 - Wifi"            // (model A1489)
  ,"iPad4,5"   : "iPad Mini 2 - Wifi + Cellular" // (model A1490)
  ,"iPad4,6"   : "iPad Mini 2 - Wifi + Cellular" // (model A1491)
  // iPad Mini 3
  ,"iPad4,7"   : "iPad Mini 3 - Wifi"            // (model A1599)
  ,"iPad4,8"   : "iPad Mini 3 - Wifi + Cellular" // (model A1600)
  ,"iPad4,9"   : "iPad Mini 3 - Wifi + Cellular" // (model A1601)
  // iPad Mini 4
  ,"iPad5,1"   : "iPad Mini 4 - Wifi"            // (model A1538)
  ,"iPad5,2"   : "iPad Mini 4 - Wifi + Cellular" // (model A1550)
  //iPad AIR 2
  ,"iPad5,3"   : "iPad Air 2 - Wifi"             // (model A1566)
  ,"iPad5,4"   : "iPad Air 2 - Wifi + Cellular"  // (model A1567)
  // iPad PRO 9.7"
  ,"iPad6,3"   : "iPad Pro - Wifi"               // (model A1673)
  ,"iPad6,4"   : "iPad Pro - Wifi + Cellular"    // (model A1674)
  //"iPad6,4": "iPad Pro - Wifi + Cellular"      // (model A1675)
  //iPad PRO 12.9"
  ,"iPad6,7"   : "iPad Pro - Wifi"               // (model A1584)
  ,"iPad6,8"   : "iPad Pro - Wifi + Cellular"    // (model A1652)
  //iPad (5th generation)
  ,"iPad6,11"  : "iPad 5 - Wifi"                 // (model A1822)
  ,"iPad6,12"  : "iPad 5 - Wifi + Cellular"      // (model A1823)
  //iPad PRO 12.9" (2nd Gen)
  ,"iPad7,1"   : "iPad Pro - Wifi"               // (model A1670)
  ,"iPad7,2"   : "iPad Pro - Wifi + Cellular"    // (model A1671)
  //"iPad7,2"    : "iPad Pro - Wifi + Cellular"  // (model A1821)
  //iPad PRO 10.5"
  ,"iPad7,3"   : "iPad Pro - Wifi"               // (model A1701)
  ,"iPad7,4"   : "iPad Pro - Wifi + Cellular"    // (model A1709)
  // iPad (6th Gen)
  ,"iPad7,5"   : "iPad 6 - WiFi"
  ,"iPad7,6"   : "iPad 6 - WiFi + Cellular"
  // iPad (7th Gen)
  ,"iPad7,11"  : "iPad - WiFi"
  ,"iPad7,12"  : "iPad - WiFi + Cellular"
  //iPad PRO 11"
  ,"iPad8,1"   : "iPad Pro - WiFi"
  ,"iPad8,2"   : "iPad Pro - 1TB, WiFi"
  ,"iPad8,3"   : "iPad Pro - WiFi + Cellular"
  ,"iPad8,4"   : "iPad Pro - 1TB, WiFi + Cellular"
  //iPad PRO 12.9" (3rd Gen)
  ,"iPad8,5"   : "iPad Pro 3 - WiFi"
  ,"iPad8,6"   : "iPad Pro 3 - 1TB, WiFi"
  ,"iPad8,7"   : "iPad Pro 3 - WiFi + Cellular"
  ,"iPad8,8"   : "iPad Pro 3 - 1TB, WiFi + Cellular"
  //iPad PRO 11" (2nd Gen)
  ,"iPad8,9"   : "iPad Pro 2 - WiFi"
  ,"iPad8,10"  : "iPad Pro 2 - 1TB, WiFi"
  //iPad PRO 12.9" (4th Gen)
  ,"iPad8,11"  : "iPad Pro 4 - (WiFi)"
  ,"iPad8,12"  : "iPad Pro 4 - (WiFi+Cellular)"
  // iPad mini 5th Gen
  ,"iPad11,1"  : "iPad mini 5 - WiFi"
  ,"iPad11,2"  : "iPad mini 5 - Wifi  + Cellular"
  // iPad Air 3rd Gen
  ,"iPad11,3"  : "iPad Air 3 - Wifi"
  ,"iPad11,4"  : "iPad Air 3 - Wifi  + Cellular"
  //iPod Touch
  ,"iPod1,1"   : "iPod Touch"
  ,"iPod2,1"   : "iPod Touch Second Generation"
  ,"iPod3,1"   : "iPod Touch Third Generation"
  ,"iPod4,1"   : "iPod Touch Fourth Generation"
  ,"iPod5,1"   : "iPod Touch 5th Generation"
  ,"iPod7,1"   : "iPod Touch 6th Generation"
  ,"iPod9,1"   : "iPod Touch 7th Generation"
  // Apple Watch
  ,"Watch1,1"  : "Apple Watch 38mm"
  ,"Watch1,2"  : "Apple Watch 38mm"
  ,"Watch2,6"  : "Apple Watch Series 1 38mm"
  ,"Watch2,7"  : "Apple Watch Series 1 42mm"
  ,"Watch2,3"  : "Apple Watch Series 2 38mm"
  ,"Watch2,4"  : "Apple Watch Series 2 42mm"
  ,"Watch3,1"  : "Apple Watch Series 3 38mm"     // (GPS+Cellular)
  ,"Watch3,2"  : "Apple Watch Series 3 42mm"     // (GPS+Cellular)
  ,"Watch3,3"  : "Apple Watch Series 3 38mm"     // (GPS)
  ,"Watch3,4"  : "Apple Watch Series 3 42mm"     // (GPS)
  ,"Watch4,1"  : "Apple Watch Series 4 40mm"     // (GPS)
  ,"Watch4,2"  : "Apple Watch Series 4 44mm"     // (GPS)
  ,"Watch4,3"  : "Apple Watch Series 4 40mm"     // (GPS+Cellular)
  ,"Watch4,4"  : "Apple Watch Series 4 44mm"     // (GPS+Cellular)
  ,"Watch5,1"  : "Apple Watch Series 5 40mm"     // (GPS)
  ,"Watch5,2"  : "Apple Watch Series 5 44mm"     // (GPS)
  ,"Watch5,3"  : "Apple Watch Series 5 40mm"     // (GPS+Cellular)
  ,"Watch5,4"  : "Apple Watch Series 5 44mm"     // (GPS+Cellular)
  // Apple TV
  ,"AppleTV5,3" : "Apple TV"
]

// MARK: TESTING METHODS

extension LIFTEvent {
    static var all: [LIFTEvent]? {
        return try? context?.fetch( fetchRequest() ) // as? [LIFTEvent]
    }
    
    static var count: Int? { // == all.count
        return try? context?.count(for: fetchRequest() )
    }
    
    static var sum: Int32 {
        let request = fetchRequest()
        request.propertiesToFetch = ["size"]
        let events =  (try? context?.fetch( request ) ?? [])!
        return events.map { $0.size } .reduce(Int32(0),+)
    }
}

// MARK: STRUCTS
public struct NetworkInfo {

    static var shared = NetworkInfo()
    private let monitor = NWPathMonitor()

    public init() {
        monitor.pathUpdateHandler = {
            switch $0.status {
              case .satisfied:
                Task { await LIFT.SDK.diagnostics?.report(.priority_log([.netConnected])) }
                break
              case .unsatisfied, .requiresConnection:
                Task { await LIFT.SDK.diagnostics?.report(.priority_log([.netDisconnected])) }
                break
                
              @unknown default:
                Task { await LIFT.SDK.diagnostics?.report(.priority_log([.netUnknown])) }
            }
         }
        
        self.monitor.start(queue: DispatchQueue(label: "SDK Network Monitoring Queue"))
    }
    
    static func startMonitoring() { _ = NetworkInfo.shared }

    /*deinit { // set shared = nil to cancel for class-based implementation
        self.monitor.cancel()
    }*/
    
    static var isConnected: Bool {
        return shared.monitor.currentPath.status == .satisfied
    }

    static var networkType: String? {
        let monitor = shared.monitor
        guard monitor.currentPath.status == .satisfied else {
              return "offline"
        }

        return [
             .wifi : "wifi"
        ,.cellular : "mobile"
        ][monitor.currentPath
            .availableInterfaces.filter {
                monitor.currentPath.usesInterfaceType($0.type)
            }.first?.type]
    }

    static var carrierName: String? {
        #if os(iOS)
        CTTelephonyNetworkInfo()
        .serviceSubscriberCellularProviders?
        .first { $0.value.carrierName != nil }?
        .value.carrierName
        #elseif os(tvOS)
        "Currently not available in tvOS"
        #endif
        // TODO: for other Apple os-es
    }
}

// MARK: EXTENSIONS
extension LIFT {

    public static func getDeviceModel() -> String {
        if let model = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return model }
        if let key = "hw.machine".cString(using: String.Encoding.utf8) {
            var size: Int = 0
            sysctlbyname(key, nil, &size, nil, 0)
            var machine = [CChar](repeating: 0, count: Int(size))
            sysctlbyname(key, &machine, &size, nil, 0)
            return String(cString: machine)
        }
        return ""
    }
}

extension Date {
    
    var epoch : Int64 {
        Int64(self.timeIntervalSince1970 * 1000)
    }
}

extension Dictionary {
    func jsonBytes(options: JSONSerialization.WritingOptions = [] ) -> Data? {
        
        do {
            let dataResult = try JSONSerialization.data(withJSONObject: self, options: options.union(.withoutEscapingSlashes) )
            return dataResult
        } catch {
            LIFT.SDK.logger.log("ERROR: Error serializing data: \(error)")
            return nil
        }
    }
}

extension Data {
    var jsonPayload: [String:Any]? {
        return try? JSONSerialization.jsonObject(with: self) as? [String:Any]
    }
}

extension String {
    var nameFromSchema: String  {
        get throws {
            let items = self.split(separator: "/")
            guard items.count == 3 else {
                throw NSError()
            }
            return String(items[1])
        }
    }
}


@propertyWrapper
struct Stored<Value> {
    var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
            total = (newValue as? any Collection)?.count == 0 ? 0 : total + 1
        }
    }

    private func total(_ key:String) -> String { "\(key)Total" }
    
    public var total: Int {
        get {
            let value = storage.value(forKey: total(key)) as? Int
            return value ?? 0
        }
        
        set {
            storage.setValue(newValue, forKey: total(key) )
        }
    }
    
    private let key: String
    private let defaultValue: Value
    private let storage: UserDefaults

    init(wrappedValue defaultValue: Value,
         key: String,
         storage: UserDefaults = .standard) {
        self.defaultValue = defaultValue
        self.key = key
        self.storage = storage
    }
}

extension Dictionary {

    init(_ slice: Slice<Dictionary>) {
        self = [:]

        for (key, value) in slice {
            self[key] = value
        }
    }

}

extension UserDefaults: @unchecked Sendable {}
// extension Notification: @unchecked Sendable {}

// Extensions for test with errors
extension LIFT {
    public enum Notification: String {
        case emptyBuffer = "emptyBuffer"
        case sentEvents = "sentEvents"
    }
    
    static public func notification(_ type: Notification) -> NSNotification.Name {
        return NSNotification.Name(rawValue: type.rawValue )
    }
}

extension LIFT.SDK {

    public final class Resources {
        
        // Discovers the resources bundle undependednt of the SPM or CocoaPod
        
        public static let bundle: Bundle = {
            let candidates = [
                // Bundle should be present here when the package is linked into an App.
                Bundle.main.resourceURL,
                
                // Bundle should be present here when the package is linked into a framework.
                Bundle(for: Resources.self).resourceURL,
            ]
            
            // TODO: Concider delegating to build system
            let bundleName = "LIFTSdk_LIFTSdk"
            
            for candidate in candidates {
                let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
                if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                    return bundle
                }
            }
            
            // Return whatever bundle this code is in as a last resort.
            return Bundle(for: Resources.self)
        }()
    }
}


extension LIFT.SDK {
    
    class HostingApplicationState {
        
        private var dataProtectionFlag: Bool
        
        private var notifications: [(name: NSNotification.Name, selector: Selector )] { [
            (name: UIApplication.protectedDataWillBecomeUnavailableNotification,
             selector: #selector(transition)),
            (name: UIApplication.protectedDataDidBecomeAvailableNotification,
             selector: #selector(transition))
        ]}
        
        @objc func transition(notification: Notification) {
            switch notification.name {
                case UIApplication.protectedDataWillBecomeUnavailableNotification:
                        dataProtectionFlag = true
                    case UIApplication.protectedDataDidBecomeAvailableNotification:
                        dataProtectionFlag = false
                    default: return
                }
        }
        
        init(isProtectedDataAvailable: Bool = true) {
            self.dataProtectionFlag = !isProtectedDataAvailable
            // Subscribe
            for notification in notifications {
                NotificationCenter.default.addObserver(self
                ,selector: notification.selector
                ,name: notification.name
                ,object: nil)
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        var isProtectedDataAvailable: Bool { !dataProtectionFlag }
    }
}

extension String: Error {}


enum EndpointType {
    case request
    case socket
}


extension String {
    var epType: EndpointType  {
        self.hasPrefix("ws:")
        ? EndpointType.socket 
        : EndpointType.request
    }
}
