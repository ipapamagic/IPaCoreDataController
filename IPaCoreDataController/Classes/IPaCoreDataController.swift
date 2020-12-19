//
//  IPaCoreDataController.swift
//  IPaCoreDataController
//
//  Created by IPa Chen on 2015/8/16.
//  Copyright (c) 2015年 A Magic Studio. All rights reserved.
//

import Foundation
import CoreData
import IPaLog
open class IPaCoreDataController :NSObject{
    
    public static let errorNotificationName = Notification.Name("IPaCoreDataController.errorNotificationName")
    
    
    public var managedObjectModel:NSManagedObjectModel
    public lazy var persistentStoreCoordinator:NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: self.sourceStoreType, configurationName: nil, at: self.dbStoreURL, options: [NSMigratePersistentStoresAutomaticallyOption: true,
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
            NotificationCenter.default.post(name: IPaCoreDataController.errorNotificationName, object: self, userInfo: ["Error":error])
        }
        return persistentStoreCoordinator
    }()
    open lazy var managedObjectContext:NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()
    var sourceStoreType:String {
        get {
            return NSSQLiteStoreType
        }
    }
    open var dbStoreURL:URL
    public init(dbName:String,dbPath:String?,modelName:String?) {
        
        
        let dbFileName = (dbName as NSString).appendingPathExtension("sqlite")!
        var momdUrl:URL?
        
        
        if let modelName = modelName {
            var modelPath:String? = nil
            modelPath = Bundle.main.path(forResource: modelName, ofType: "momd")
            if modelPath == nil {
                modelPath = Bundle.main.path(forResource: modelName, ofType: "mom")
            }
            momdUrl = URL(fileURLWithPath: modelPath!)
            
        }
        if let momdUrl = momdUrl {
            managedObjectModel = NSManagedObjectModel(contentsOf: momdUrl)!
            
        }
        else {
            managedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!
            
        }
        var storePath:String
        if let dbPath = dbPath {
            storePath = dbPath
        }
        else {
            storePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true).first)!
        }
        storePath = (storePath as NSString).appendingPathComponent(dbFileName)
        
        
        //bug handling
        var backupFilePath = (storePath as NSString).deletingLastPathComponent
        backupFilePath = (backupFilePath as NSString).appendingPathComponent("backup.sqlite")
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: backupFilePath) {
            do {
                try fileManager.removeItem(atPath: backupFilePath)
                
                backupFilePath = (backupFilePath as NSString).deletingLastPathComponent
                backupFilePath = (backupFilePath as NSString).appendingPathComponent("backup.sqlite-shm")
                try fileManager.removeItem(atPath: backupFilePath)
                backupFilePath = (backupFilePath as NSString).deletingLastPathComponent
                backupFilePath = (backupFilePath as NSString).appendingPathComponent("backup.sqlite-wal")
                try fileManager.removeItem(atPath: backupFilePath)
                
            }
            catch let error as NSError{
                print("\(error)")
            }
            catch {
                
            }
        }
        
        storePath = (storePath as NSString).deletingPathExtension
        storePath = (storePath as NSString).appendingPathExtension("sqlite")!
        
        
        dbStoreURL = URL(fileURLWithPath: storePath)
        
        
        /*
         Set up the store.
         For the sake of illustration, provide a pre-populated default store.
         */
        
    }
    public convenience init(dbName:String,modelName:String)
    {
        self.init(dbName:dbName,dbPath:nil,modelName:modelName)
    }
    public convenience init(modelName:String)
    {
        self.init(dbName:modelName,modelName:modelName)
    }
    //MARK: Migration
    func findTargetModel(from array:[String],bundle:Bundle,sourceModel:NSManagedObjectModel) -> (String,NSManagedObjectModel,NSMappingModel)? {
        for momPath in array {
            
            if let model =  NSManagedObjectModel(contentsOf: URL(fileURLWithPath: momPath)) {
                
                if let mappingModel = NSMappingModel(from:[bundle], forSourceModel: sourceModel, destinationModel: model) {
                    let targetModelName = ((momPath as NSString).lastPathComponent as NSString).deletingPathExtension
                    
                    
                    return (targetModelName,model,mappingModel)
                }

            }
        }
        return nil
        
        
    }
    open func makeMigration() -> Bool {
        let sourceURL = dbStoreURL
        let bundle = Bundle.main
        var sourceModel:NSManagedObjectModel
        do {
            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: sourceStoreType, at: sourceURL, options: nil)
            if managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) {
                return true
            }
            if let model = NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: sourceMetadata) {
                sourceModel = model
            }
            else {
                return false
            }
        }
        catch let error as NSError {
            NotificationCenter.default.post(name: IPaCoreDataController.errorNotificationName, object: self, userInfo: ["Error":error])
            return false
        }
        catch {
            return false
        }
        //search model paths in bundle
        var targetModel:NSManagedObjectModel?
        var targetMappingModel:NSMappingModel?
        var targetModelName:String?
        let momdArray = bundle.paths(forResourcesOfType: "momd", inDirectory: nil)
        
        for momdPath in momdArray {
            
            let resourceSubpath = (momdPath as NSString).lastPathComponent
            let array = bundle.paths(forResourcesOfType: "mom", inDirectory: resourceSubpath)
            if let (modelName,model,mappingModel) = self.findTargetModel(from: array, bundle: bundle, sourceModel: sourceModel)
            {
                targetModelName = modelName
                targetModel = model
                targetMappingModel = mappingModel
                break
            }
            
        }
        if targetModel == nil {
            let otherModels = bundle.paths(forResourcesOfType: "mom", inDirectory: nil)
            
            if let (modelName,model,mappingModel) = self.findTargetModel(from: otherModels, bundle: bundle, sourceModel: sourceModel)
            {
                targetModelName = modelName
                targetModel = model
                targetMappingModel = mappingModel
            }
            
        }
        guard let destinationModel = targetModel,let destinationMappingModel = targetMappingModel else {
            print("destination model not found!!")
            return false
        }
        
        
        // Build a path to write the new store
        let storePath:NSString = sourceURL.path as NSString
        let destinationURL = URL(fileURLWithPath:"\(storePath.deletingPathExtension).\(targetModelName!).\(storePath.pathExtension)")
        //start migration
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        manager.addObserver(self, forKeyPath: "migrationProgress", options: .new, context: nil)
        do {
            try manager.migrateStore(from: sourceURL, sourceType: sourceStoreType, options: nil, with: destinationMappingModel, toDestinationURL: destinationURL, destinationType: sourceStoreType, destinationOptions: nil)
            manager.removeObserver(self, forKeyPath: "migrationProgress")
        }
        catch let error as NSError {
            NotificationCenter.default.post(name: IPaCoreDataController.errorNotificationName, object: self, userInfo: ["Error":error])
            manager.removeObserver(self, forKeyPath: "migrationProgress")
            return false
        }
        catch {
            manager.removeObserver(self, forKeyPath: "migrationProgress")
            return false
        }
        
        // Migration was successful, move the files around to preserve the source in case things go bad
        let guid = ProcessInfo.processInfo.globallyUniqueString
        let backupPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(guid)
        let fileManager = FileManager.default
        do {
            try fileManager.moveItem(atPath: sourceURL.path, toPath: backupPath)
            try fileManager.moveItem(atPath: destinationURL.path, toPath: sourceURL.path)
            
        }
        catch let error as NSError {
            NotificationCenter.default.post(name: IPaCoreDataController.errorNotificationName, object: self, userInfo: ["Error":error])
            return false
        }
        catch {
            return false
        }
        
        return makeMigration()
        
    }
    //MARK: Public
    open func count(with fetchRequest:NSFetchRequest<NSFetchRequestResult>,maximumCount:Int? = nil) -> Int {
        if let maximumCount = maximumCount {
            fetchRequest.fetchBatchSize = maximumCount
        }
        do {
            let count = try self.managedObjectContext.count(for: fetchRequest)
            return count
        }
        catch let error as NSError {
            NotificationCenter.default.post(name: IPaCoreDataController.errorNotificationName, object: self, userInfo: ["Error":error])
        }
        return 0
        
    }
    open func count(with entityName:String,maximumCount:Int? = nil) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.includesSubentities = false
        return self.count(with:fetchRequest)
    }
    open func checkMigration() -> Bool {
        let path = self.dbStoreURL.path
        if !FileManager.default.fileExists(atPath: path) {
            return false
        }
        //check migration
        do {
            
            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: self.sourceStoreType, at: self.dbStoreURL, options: nil)
            
            // Migration is needed if destinationModel is NOT compatible
            if !managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) {
                //migration needed
                
                
                
                
            }
            
            
        }
        catch let error as NSError {
            NotificationCenter.default.post(name: IPaCoreDataController.errorNotificationName, object: self, userInfo: ["Error":error])
            return false
        }
        catch {
            
        }
        return true
        
        
    }
    open func deleteEntity(_ entityName:String) {
        let fetchAllObjects = NSFetchRequest<NSManagedObject>()
        fetchAllObjects.entity = NSEntityDescription.entity(forEntityName: entityName, in: managedObjectContext)
        fetchAllObjects.includesPropertyValues = false //only fetch the managedObjectID
        
        do {
            let allObjects = try managedObjectContext.fetch(fetchAllObjects)
            for object in allObjects {
                
                managedObjectContext.delete(object)
                
            }
        } catch let error as NSError {
            
            print("\(error)");
        }
        
        
        
    }
    //MARK: core data stack
    open func save() {
        do {
            if managedObjectContext.hasChanges {
                try managedObjectContext.save()
            }
        } catch let error as NSError {
            
            NotificationCenter.default.post(name: IPaCoreDataController.errorNotificationName, object: self, userInfo: ["Error":error])
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.save()
            }
        }
    }
    
    
    open func createEntity<T:NSManagedObject>() -> T {
        let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: managedObjectContext)!
        return NSManagedObject(entity: entityDescription, insertInto: managedObjectContext) as! T
        
    }
    open func deleteObject(_ object:NSManagedObject) {
        managedObjectContext.delete(object)
        
    }
    
    open func fetchFirst<T:NSFetchRequestResult>(with managedObjectContext:NSManagedObjectContext? = nil,format predicateFormat:String,_ args: CVarArg...) -> T? {
        let request = NSFetchRequest<T>(entityName: String(describing:T.self))
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: predicateFormat, argumentArray: args)
        let list:[T]? = self.fetch(request, with: managedObjectContext)
        return list?.first
    }
    open func fetch<T:NSFetchRequestResult>(with managedObjectContext:NSManagedObjectContext? = nil,limit:Int,format predicateFormat:String,_ args: CVarArg...) -> [T]? {
        let request = NSFetchRequest<T>(entityName: String(describing:T.self))
        request.fetchLimit = limit
        request.predicate = NSPredicate(format: predicateFormat, argumentArray: args)
        let list:[T]? = self.fetch(request, with: managedObjectContext)
        return list
    }
    open func fetch<T:NSFetchRequestResult>(_ request:NSFetchRequest<T>,with managedObjectContext:NSManagedObjectContext? = nil) -> [T]? {
        var fetchResult:[T]?
        var usedMoc = self.managedObjectContext
        if let moc = managedObjectContext {
            usedMoc = moc
        }
        do {
            try fetchResult = usedMoc.fetch(request)
        } catch let error as NSError {
            
            NotificationCenter.default.post(name: IPaCoreDataController.errorNotificationName, object: self, userInfo: ["Error":error])
        }
        return fetchResult
    }
    open func createWorkerManagedContext(_ concurencyType:NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let workerMOC = NSManagedObjectContext(concurrencyType: concurencyType)
        workerMOC.parent = managedObjectContext
        return workerMOC
    }
    open func managedObject(for uri:URL, context:NSManagedObjectContext? = nil) -> NSManagedObject? {
        guard let managedObjectID = self.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri) else {
            return nil
        }
        let managedObjectContext = context ?? self.managedObjectContext
        return managedObjectContext.object(with: managedObjectID)
    }
    //MARK:Observer
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "migrationProgress" ,let manager = object as? NSMigrationManager {
            print("migration progress \(manager.migrationProgress)")
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}


