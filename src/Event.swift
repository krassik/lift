//
//  Event.swift
//
//  Created by Krassi + AI
//

import CoreData
import Network
import os
import UIKit

public class LIFTEvent: NSManagedObject {
    
    private(set) public static var averageSize = 0
    
    public static func setBufferAverage() {
        
        guard let context = context else {
            averageSize = 0
            return
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LIFTEvent")
        let expression = NSExpressionDescription()
        expression.expression =  NSExpression(forFunction: "average:", arguments:[NSExpression(forKeyPath: "size")])
        expression.name = "averageSize"
        expression.expressionResultType = .integer32AttributeType
        
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let results = try? context.fetch(request)
        
        averageSize =  Int((results as? [[String:Int32]])?.first?["averageSize"] ?? 0)
    }
    
    /*private convenience init() {
     self.init(LIFTEvent.self)!
     }*/
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    convenience init?(_ type: LIFTEvent.Type) {

        guard let context = type.context,
              let entity = NSEntityDescription.entity(forEntityName: "LIFTEvent", in: context)
        else {
            let msg = "Initialization must preceed capture."
            LIFT.SDK.logger.log(level: .error, msg )
#if DEBUG
            assertionFailure(msg)
#endif
            return nil
        }
        
        self.init(entity: entity, insertInto: context)
    }
    
    public static var context: NSManagedObjectContext? = nil
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        timestamp = Date.now.epoch
        id = UUID()
    }
 
    public func save(_ nextAction: ()->() = {}) {
        do {
            try LIFTEvent.save()
            log("New")
            
            
            if ( LIFT.SDK.diagnostics != nil
                 // &&  (try? schema?.nameFromSchema != "diagnostics")!
                ) {
                Task {
                    await LIFT.SDK.diagnostics?.report(.received([ self.schema ?? "unknown" ]))
                }
            }
            
            nextAction()
            
            if LIFTEvent.averageSize == 0 {
                LIFTEvent.averageSize = Int(size)
                return
            }
            
            // Updates the average with last event size only
            LIFTEvent.averageSize = (LIFTEvent.averageSize + Int(size)) / 2
            
        } catch {
            log(level: .error,"")
        }
    }
    
    static func save() throws {
        
        guard let context = LIFTEvent.context, context.hasChanges else {
            return // avoid unnecessary work
        }
        
        // try iOS15
        context.performAndWait {
            
                do { // iOS14
                    
                    guard LIFT.SDK.state.isProtectedDataAvailable else {
                        throw "device locked"
                    }
                
                    try context.save()
                    try context.parent?.save()
                    
                    
                } catch {
                    LIFT.SDK.logger.log(level: .error, "\(error)")
                }
        }
    }
}

extension LIFTEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LIFTEvent> {
        return NSFetchRequest<LIFTEvent>(entityName: "LIFTEvent")
    }

    @NSManaged public var effect: EffectValue?
    @NSManaged public var id: UUID?
    @NSManaged public var payload: Data?
    @NSManaged public var retryCount: Int16
    @NSManaged public var size: Int32
    @NSManaged public var timestamp: Int64
    @NSManaged public var schema: String?
    @NSManaged public var attempts: NSSet?
}

// MARK: Generated accessors for attempts
extension LIFTEvent {

    @objc(addAttemptObject:)
    @NSManaged public func addToAttempts(_ value: LIFTAttempt)

    @objc(removeAttemptObject:)
    @NSManaged public func removeFromAttempts(_ value: LIFTAttempt)

    @objc(addAttempts:)
    @NSManaged public func addToAttempts(_ values: NSSet)

    @objc(removeAttempts:)
    @NSManaged public func removeFromAttempts(_ values: NSSet)

}

extension LIFTEvent : Identifiable {

}
