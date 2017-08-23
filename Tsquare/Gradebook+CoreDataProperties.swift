//
//  Gradebook+CoreDataProperties.swift
//  
//
//  Created by Prabhav Chawla on 8/23/17.
//
//

import Foundation
import CoreData


extension Gradebook {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Gradebook> {
        return NSFetchRequest<Gradebook>(entityName: "Gradebook")
    }

    @NSManaged public var score: NSObject?
    @NSManaged public var siteURL: NSObject?
    @NSManaged public var classObject: Class?

}
