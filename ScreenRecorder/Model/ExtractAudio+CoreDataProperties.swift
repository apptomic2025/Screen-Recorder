//
//  ExtractAudio+CoreDataProperties.swift
//  
//
//  Created by Sajjad Hosain on 26/2/25.
//
//

import Foundation
import CoreData


extension ExtractAudio {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExtractAudio> {
        return NSFetchRequest<ExtractAudio>(entityName: "ExtractAudio")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var duration: Double
    @NSManaged public var name: String?
    @NSManaged public var thumbName: String?

}
