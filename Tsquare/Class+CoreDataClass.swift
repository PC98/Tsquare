//
//  Class+CoreDataClass.swift
//
//
//  Created by Prabhav Chawla on 8/23/17.
//
//

import Foundation
import CoreData

@objc(Class)
public class Class: NSManagedObject {
    convenience init(name: String, siteURL: URL, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Class", in: context) {
            self.init(entity: ent, insertInto: context)
            
            self.name = name
            self.siteURL = siteURL as NSObject
        }  else {
            fatalError("Error")
        }
    }
}
