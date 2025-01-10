//
//  Session.swift
//  
//
//  Created by Krassi + AI
//

import UIKit

class Session {

    private var lastActivityStamp: Date
    private var id: String
    
    private enum key {
        static let lastActivityStamp = "LIFT.lastActivityStamp"
        static let id = "LIFT.sessionID"
        static let backSwitchTime  = "LIFT.backSwitchTime"
    }
    
    var timeout: (foreground: TimeInterval, background: TimeInterval)
    
    private let observationList = [
        (notificationName: UIApplication.didBecomeActiveNotification,
                 selector: #selector(switchToForeground)),
        (notificationName: UIApplication.willResignActiveNotification,
                 selector: #selector(switchToBackground))
    ]
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init(timeout: (foreground: TimeInterval, background: TimeInterval), lifecycle: Bool = false) {
    
        self.timeout = timeout
        
        self.id = UserDefaults.standard.string(forKey: key.id) ?? UUID().uuidString
        self.lastActivityStamp =
                  UserDefaults.standard.object(forKey: key.lastActivityStamp)
        as? Date ?? Date()
        
        guard lifecycle else { return }
        
        // Subscribe
        for lifecycleEvent in observationList {
            NotificationCenter.default.addObserver(self
            ,selector: lifecycleEvent.selector
            ,name: lifecycleEvent.notificationName
            ,object: nil)
        }
    }
    
    private func nextSession() {
        // Starts new session here
        id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key.id)
        sync(lastValue: id)
    }
    
    private func sync(lastValue: Any = "") {
        if !UserDefaults.standard.synchronize() {
            log(level: .warn, "\(lastValue) did not sync.")
        }
    }
    
    func id(after timestamp: Int64) -> String {
        
        let incomingTime = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000 )
        
        if incomingTime.timeIntervalSince(lastActivityStamp) > timeout.foreground {
            nextSession()
        }
        
        lastActivityStamp = incomingTime
        UserDefaults.standard.set(lastActivityStamp, forKey: key.lastActivityStamp)
        
        return id
    }
            
    @objc private func switchToForeground(_: NSNotification) {
        
        guard let backSwitchStamp = UserDefaults.standard.object(forKey: key.backSwitchTime)
                as? Date else {
            return
        }
        
        if Date().timeIntervalSince(backSwitchStamp) > timeout.background {
            nextSession()
        }
    }
    
    @objc private func switchToBackground(_: NSNotification) {
        let now = Date()
        UserDefaults.standard.set(now, forKey: key.backSwitchTime)
        sync(lastValue: now)
    }
}
