//
//  IPaCoreDataController.swift
//  IPaCoreDataController
//
//  Created by IPa Chen on 2015/8/16.
//  Copyright (c) 2015年 A Magic Studio. All rights reserved.
//

import Foundation
import CoreData
public class IPaCoreDataController {
    
    var managedObjectModel:NSManagedObjectModel
    var persistentStoreCoordinator:NSPersistentStoreCoordinator
    var managedObjectContext:NSManagedObjectContext
    init(dbName:String,modelName:String?,dbPath:String?) {
        let dbFileName = (dbName as NSString).stringByAppendingPathExtension(".sqlite")!
        var momdUrl:NSURL?
        if let modelName = modelName {
            var modelPath:String? = nil
            modelPath = NSBundle.mainBundle().pathForResource(modelName, ofType: "momd")
            if modelPath == nil {
                modelPath = NSBundle.mainBundle().pathForResource(modelName, ofType: "mom")
            }
            momdUrl = NSURL(fileURLWithPath: modelPath!)

        }
        if let momdUrl = momdUrl {
            managedObjectModel = NSManagedObjectModel(contentsOfURL: momdUrl)!

        }
        else {
            managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(nil)!

        }
        var storePath:String
        if let dbPath = dbPath {
            storePath = dbPath
        }
        else {
            storePath = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true).first)!
        }
        storePath = (storePath as NSString).stringByAppendingPathComponent(dbFileName)
        let storeUrl = NSURL(fileURLWithPath: storePath)
        /*
        Set up the store.
        For the sake of illustration, provide a pre-populated default store.
        */
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: nil)
            /*
            Replace this implementation with code to handle the error appropriately.
            
            abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
            
            Typical reasons for an error here include:
            * The persistent store is not accessible
            * The schema for the persistent store is incompatible with current managed object model
            Check the error message to determine what the actual problem was.
            */
            
            
        
        }
        catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
            abort();
            
        }
        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
    }
    convenience init(dbName:String,modelName:String)
    {
        self.init(dbName:dbName,modelName:modelName,dbPath:nil)
    }
    convenience init(modelName:String)
    {
        self.init(dbName:modelName,modelName:modelName)
    }
    public func deleteEntity(entityName:String) {
        let fetchAllObjects = NSFetchRequest()
        fetchAllObjects.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext)
        fetchAllObjects.includesPropertyValues = false //only fetch the managedObjectID

        do {
            let allObjects = try managedObjectContext.executeFetchRequest(fetchAllObjects)
            for object in allObjects {
                if let object = object as? NSManagedObject {
                    managedObjectContext.deleteObject(object)
                }
            }
        } catch let error as NSError {

            print("\(error)");
        }

        

    }
    //MARK: core data stack
    public func save() {
        do {
            if managedObjectContext.hasChanges {
                try managedObjectContext.save()
            }
        } catch let error as NSError {
            
            print("Unresolved error \(error), \(error.userInfo)");
           
            abort();
        }
    }
    
    
    public func insertNewObject(entityName:String) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) 
    }
    public func deleteObject(object:NSManagedObject) {
        managedObjectContext.deleteObject(object)
        save()
    }
    public func fetch(request:NSFetchRequest) -> [AnyObject]? {
        var fetchResult:[AnyObject]?
        do {
            try fetchResult = managedObjectContext.executeFetchRequest(request)
        } catch let error as NSError {
            
            print("Unresolved error \(error), \(error.userInfo)");
            
            abort();
        }
        return fetchResult
    }
}


