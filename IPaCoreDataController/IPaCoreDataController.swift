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
        let dbFileName = dbName.stringByAppendingPathExtension(".sqlite")!
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
            storePath = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true).first) as! String
        }
        storePath = storePath.stringByAppendingPathComponent(dbFileName)
        let storeUrl = NSURL(fileURLWithPath: storePath)
        var error:NSError?
        /*
        Set up the store.
        For the sake of illustration, provide a pre-populated default store.
        */
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        if (persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: nil, error: &error) == nil) {
            /*
            Replace this implementation with code to handle the error appropriately.
            
            abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
            
            Typical reasons for an error here include:
            * The persistent store is not accessible
            * The schema for the persistent store is incompatible with current managed object model
            Check the error message to determine what the actual problem was.
            */
            
            print("Unresolved error \(error), \(error?.userInfo)")
            abort();
            
        }
        managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
    }
    public func deleteEntity(entityName:String) {
        var fetchAllObjects = NSFetchRequest()
        fetchAllObjects.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext)
        fetchAllObjects.includesPropertyValues = false //only fetch the managedObjectID
        var error:NSError?
        var allObjects = managedObjectContext.executeFetchRequest(fetchAllObjects, error: &error)
        
        // uncomment next line if you're NOT using ARC

        if let error = error {
            print("\(error)");
        }
        if let allObjects = allObjects {
            for object in allObjects {
                if let object = object as? NSManagedObject {
                    managedObjectContext.deleteObject(object)
                }
            }
        }
    }
    //MARK: core data stack
    public func save() {
        var error:NSError?
        if managedObjectContext.hasChanges && !managedObjectContext.save(&error)
            {
                /*
                Replace this implementation with code to handle the error appropriately.
                
                abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                */
                if let error = error {
                    print("Unresolved error \(error), \(error.userInfo)");
                }
                abort();
            }
    }
    
    
    public func insertNewObject(entityName:String) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! NSManagedObject
    }
    public func deleteObject(object:NSManagedObject) {
        managedObjectContext.deleteObject(object)
        save()
    }
    public func fetch(entityName:String,request:NSFetchRequest) -> [AnyObject]? {
        request.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext)
        return managedObjectContext.executeFetchRequest(request, error: nil)
    }
}


