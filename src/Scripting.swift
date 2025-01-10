//
//  Scripts.swift
//
//  Scripting Systems
//  Created by Krassi + AI
//
//

import Foundation

@objc public class EffectValue: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool = true
    
    let path: String
    let delay: Int

    public func encode(with coder: NSCoder) {
        coder.encode(self.path, forKey: "path")
        coder.encode(self.delay, forKey: "delay")
    }

    public required init?(coder decoder: NSCoder) {
        self.path  = (decoder.decodeObject(of: [NSString.self], forKey: "path") as? String) ?? "/code/200"
        self.delay = decoder.decodeInteger(forKey: "delay")
    }

    public init(_ effect: Effect) {
        switch effect.code {
          case .code(let codeValue):
            self.path = "/code/\(codeValue)"
          case .path(let pathValue):
            self.path = pathValue
        }

        if case .delay(let delayValue) = effect.delay {
            self.delay = delayValue
        } else {
            self.delay = 0
        }
    }
}

@objc(EffectValueTransformer)
class EffectValueTransformer: ValueTransformer {

    override func transformedValue(_ value: Any?) -> Any? {
        guard let effect = value as? EffectValue else {
            return nil
        }

        do {
            return try NSKeyedArchiver.archivedData(withRootObject: effect, requiringSecureCoding: true)
        } catch {
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            return nil
        }

        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: EffectValue.self, from: data)
        } catch {
            return nil
        }
    }
}

extension HTTPCollector {
    func request(from event: LIFTEvent) -> URLRequest {

        guard LIFT.SDK.isScripted else {
            return request
        }
        
        var maybeEffect: EffectValue? = nil
        
        LIFT.Event.context?.performAndWait {
            maybeEffect = event.effect
        }
        
        guard let effect = maybeEffect else { return request }

        let firstAttemptCode = effect.path

        let retro: (() -> Double) -> Bool =
        // case:
        ["/exit": { $0() > 0.5 }
        //,"/code/501" : { $0() > 0.5 }
        //,"/code/502" : { $0() > 0.5 }
        //,"/code/503" : { $0() > 0.5 }
        //,"/code/504" : { $0() > 0.5 }
        //,"/code/505" : { $0() > 0.5 }
        ][firstAttemptCode] // switch
        //default:
        ?? { $0() >= 0 } // do the same thing each time if retrying
        // ?? {(1/Double(self.retryCount) as Double) >= $0()}

        let nextAttemptCode = retro(drand48) ? firstAttemptCode : "/code/200"

        log("Expect \(nextAttemptCode) response ...")

        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        components?.path = nextAttemptCode

        if effect.delay > 0 {
            components?.queryItems = [URLQueryItem(name: "ms", value: String(effect.delay))]
        }

        var modified_request = URLRequest(url: (components?.url)!)
        modified_request.httpMethod = request.httpMethod
        modified_request.setValue(request.value(forHTTPHeaderField: "Content-Type")!, forHTTPHeaderField: "Content-Type")

        return modified_request
    }
}

public enum Code {
    case code(Int)
    case path(String)
}

public enum Delay {
    case delay(Int)
}

public typealias Effect = (code: Code, delay: Delay)
public typealias Step = (delay: ()->Int, content: Any, effect: ()->Effect)
public typealias Script = [Step]

extension LIFT.SDK {

    public static func runScript(_ script: Script, times: Int = Int.max, rate: Int = 0,
                onEvent: (() -> Void)? = nil,
                onReady: (() -> Void)? = nil,
                _ perform: @escaping (Step) -> Void ) {

        guard LIFTEvent.context != nil else {
            return
        }

        Task {
            for _ in 1...times {
                for step in script {
                    let delay = rate > 0 ? 1000/rate : step.delay()
                    try? await Task.sleep(nanoseconds:  UInt64( delay * 1000000 ) )
                    perform(step)
                    onEvent?()
                }
            }
            onReady?()
        }
    }
}
