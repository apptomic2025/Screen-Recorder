//
//  VoiceRecord+CoreDataProperties.swift
//  
//
//  Created by Sajjad Hosain on 26/2/25.
//
//

import Foundation
import CoreData


extension VoiceRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VoiceRecord> {
        return NSFetchRequest<VoiceRecord>(entityName: "VoiceRecord")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var duration: Double
    @NSManaged public var name: String?

}
