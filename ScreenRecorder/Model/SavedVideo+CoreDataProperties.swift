//
//  SavedVideo+CoreDataProperties.swift
//  
//
//  Created by Sajjad Hosain on 26/2/25.
//
//

import Foundation
import CoreData


extension SavedVideo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedVideo> {
        return NSFetchRequest<SavedVideo>(entityName: "SavedVideo")
    }

    @NSManaged public var date: Date?
    @NSManaged public var displayName: String?
    @NSManaged public var duration: Double
    @NSManaged public var index: Int32
    @NSManaged public var name: String?
    @NSManaged public var size: String?
    @NSManaged public var thumbName: String?
    @NSManaged public var type: String?

}
