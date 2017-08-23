//
//  Class+CoreDataProperties.swift
//  
//
//  Created by Prabhav Chawla on 8/23/17.
//
//

import Foundation
import CoreData


extension Class {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Class> {
        return NSFetchRequest<Class>(entityName: "Class")
    }

    @NSManaged public var name: String?
    @NSManaged public var siteURL: NSObject?
    @NSManaged public var gradebook: Gradebook?

}
