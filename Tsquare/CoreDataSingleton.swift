//
//  CoreDataSingleton.swift
//
//  Created by Prabhav Chawla on 7/7/17.
//  Copyright © 2017 Prabhav Chawla. All rights reserved.
//
import UIKit
import CoreData

/// A class to contain CoreData components that this app makes use of.
class CoreDataSingleton {
    
    /// Context to save to the store coordinator. Runs in a private queue.
    var persistingContext: NSManagedObjectContext!
    /// Data is fetched and displayed from this context. Runs in main queue.
    var context: NSManagedObjectContext!
    /// Data is added to this context. Runs in a private queue.
    var backgroundContext: NSManagedObjectContext!
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Tsquare")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    /// A shared common object
    static let shared = CoreDataSingleton()
    
    private init() { // set up NSManagedObjectContexts
        self.persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.persistingContext.persistentStoreCoordinator = self.persistentContainer.persistentStoreCoordinator
        
        self.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.context.parent = self.persistingContext
        
        self.backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.backgroundContext.parent = self.context
    }

    /// A standard method to save data to disk.
    func saveContext () {
        self.context.performAndWait() {
            if self.context.hasChanges {
                do {
                    try self.context.save()
                } catch {
                    fatalError("Error while saving main context: \(error)")
                }
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
}
