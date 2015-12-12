//
//  IPaCoreDataController.swift
//  IPaCoreDataController
//
//  Created by IPa Chen on 2015/8/16.
//  Copyright (c) 2015年 A Magic Studio. All rights reserved.
//

import Foundation
import CoreData
public class IPaCoreDataController :NSObject{
    
    var managedObjectModel:NSManagedObjectModel
    lazy var persistentStoreCoordinator:NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(self.sourceStoreType, configuration: nil, URL: self.dbStoreURL, options: [NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true])
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
        return persistentStoreCoordinator
    }()
    lazy var managedObjectContext:NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    var sourceStoreType:String {
        get {
            return NSSQLiteStoreType
        }
    }
    var dbStoreURL:NSURL
    init(dbName:String,dbPath:String?,modelName:String?) {

        
        let dbFileName = (dbName as NSString).stringByAppendingPathExtension("sqlite")!
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

        //bug handling
        
        let bugFileName = (dbName as NSString).stringByAppendingPathExtension(".sqlite")!
        let fileManager = NSFileManager.defaultManager()
        let bugFilePath = (storePath as NSString).stringByAppendingPathComponent(bugFileName)
        
        storePath = (storePath as NSString).stringByAppendingPathComponent(dbFileName)
        
        
        if fileManager.fileExistsAtPath(bugFilePath) {
            do {
                try fileManager.moveItemAtPath(bugFilePath, toPath: storePath)
            }
            catch {
                
            }
        }
        
        
        
        
        dbStoreURL = NSURL(fileURLWithPath: storePath)
        

        /*
        Set up the store.
        For the sake of illustration, provide a pre-populated default store.
        */
       
    }
    convenience init(dbName:String,modelName:String)
    {
        self.init(dbName:dbName,dbPath:nil,modelName:modelName)
    }
    convenience init(modelName:String)
    {
        self.init(dbName:modelName,modelName:modelName)
    }
    //MARK: Migration

    public func makeMigration() -> Bool {
        let sourceURL = dbStoreURL
        let bundle = NSBundle.mainBundle()
        var sourceModel:NSManagedObjectModel
        do {
            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(sourceStoreType, URL: sourceURL, options: nil)
            if managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: sourceMetadata) {
                return true
            }
            sourceModel = NSManagedObjectModel.mergedModelFromBundles([bundle], forStoreMetadata: sourceMetadata)!
            
        }
        catch let error as NSError {
            print("\(error)")
            return false
        }
        catch {
            return false
        }
        //search model paths in bundle
        var targetModel:NSManagedObjectModel?
        var targetMappingModel:NSMappingModel?
        var targetModelName:String?
        let momdArray = bundle.pathsForResourcesOfType("momd", inDirectory: nil)
        
        for momdPath in momdArray {
            
            let resourceSubpath = (momdPath as NSString).lastPathComponent
            let array = bundle.pathsForResourcesOfType("mom", inDirectory: resourceSubpath)
            for momPath in array {
                


                if let model =  NSManagedObjectModel(contentsOfURL: NSURL(fileURLWithPath: momPath)) {
                    
                    targetMappingModel = NSMappingModel(fromBundles:[bundle], forSourceModel: sourceModel, destinationModel: model)
                    if let _ = targetMappingModel {
                        targetModelName = ((momPath as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
                        targetModel = model
                        break
                    }
                }
            }
            if let _ = targetModel  {
                break
            }
        }
        if targetModel == nil {
            let otherModels = bundle.pathsForResourcesOfType("mom", inDirectory: nil)
            for momPath in otherModels {
                if let model =  NSManagedObjectModel(contentsOfURL: NSURL(fileURLWithPath: momPath)) {
                    
                    
                    targetMappingModel = NSMappingModel(fromBundles:[bundle], forSourceModel: sourceModel, destinationModel: targetModel)
                    if let _ = targetMappingModel {
                        targetModelName = ((momPath as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
                        targetModel = model
                        break
                    }
                }
            }
        }
        guard let destinationModel = targetModel else {
            print("destination model not found!!")
            return false
        }
        targetMappingModel = NSMappingModel(fromBundles:[bundle], forSourceModel: sourceModel, destinationModel: destinationModel)
        if targetMappingModel == nil {
            do {
                targetMappingModel = try NSMappingModel.inferredMappingModelForSourceModel(sourceModel, destinationModel: destinationModel)
            }
            catch let error as NSError {
                print("\(error)")
                return false
            }
            catch {
                return false
            }
        }
        guard let destinationMappingModel = targetMappingModel else {
            print("can not create Mapping Model")
            return false
        }
        // Build a path to write the new store
        let storePath:NSString = sourceURL.path!
        let destinationURL = NSURL(fileURLWithPath:"\(storePath.stringByDeletingPathExtension).\(targetModelName!).\(storePath.pathExtension)")
        //start migration
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        manager.addObserver(self, forKeyPath: "migrationProgress", options: .New, context: nil)
        do {
            try manager.migrateStoreFromURL(sourceURL, type: sourceStoreType, options: nil, withMappingModel: destinationMappingModel, toDestinationURL: destinationURL, destinationType: sourceStoreType, destinationOptions: nil)
            manager.removeObserver(self, forKeyPath: "migrationProgress")
        }
        catch let error as NSError {
            print("\(error)")
            manager.removeObserver(self, forKeyPath: "migrationProgress")
            return false
        }
        catch {
            manager.removeObserver(self, forKeyPath: "migrationProgress")
            return false
        }

        // Migration was successful, move the files around to preserve the source in case things go bad
        let guid = NSProcessInfo.processInfo().globallyUniqueString
        let backupPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(guid)
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.moveItemAtPath(sourceURL.path!, toPath: backupPath)
            try fileManager.moveItemAtPath(destinationURL.path!, toPath: sourceURL.path!)
            
        }
        catch let error as NSError {
            print("\(error)")
            return false
        }
        catch {
            return false
        }

        return makeMigration()
        
    }
    //MARK: Public
    
    public func checkMigration() -> Bool {
        
        guard let path = self.dbStoreURL.path where NSFileManager.defaultManager().fileExistsAtPath(path) else {
            return false
        }
        //check migration
        do {

            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(self.sourceStoreType, URL: self.dbStoreURL, options: nil)

                // Migration is needed if destinationModel is NOT compatible
            if !managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: sourceMetadata) {
                //migration needed

                
                
                
            }


        }
        catch let error as NSError {
            print("\(error)");
            return false
        }
        catch {
            
        }
        return true
        
        
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
    public func createWorkerManagedContex(concurencyType:NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let workerMOC = NSManagedObjectContext(concurrencyType: concurencyType)
        workerMOC.parentContext = managedObjectContext
        return workerMOC
    }
    
    //MARK:Observer
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "migrationProgress" ,let manager = object as? NSMigrationManager {
            print("progress \(manager.migrationProgress)")
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}


