//
//  IPaCoreDataController.h
//
//  Created by IPaPa on 2011/6/8.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


//params key for initial,
//default IPaCoreDataController load all modal objects in bundle
//you can use this parameter to load single modal if you want
#define IPaCoreDataPKey_SingleObjectModel @"IPaCoreDataPKey_SingleObjectModel"
//Database path, default path is "Document"
#define IPaCoreDataPKey_DBPath @"IPaCoreDataPKey_DBPath"
@interface IPaCoreDataController : NSObject {


}
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (IPaCoreDataController*) initDBWithName:(NSString*)dbName withParam:(NSDictionary*)params;
- (void)save;
- (id) insertNewObjectForEntityForName:(NSString*)entityName;
- (void) deleteObject:(NSManagedObject *)object;
/** delete all data from entity
 @param entityName entityName
 */
- (void) deleteEntity:(NSString*)entityName;
- (NSFetchedResultsController*)getFetchedResultsWithEntity:(NSString*)entityName 
												SortKey:(NSString*)sortKey 
												Ascending:(bool)ascending 
												CacheName:(NSString*)cacheName;

-(NSArray*)fetchResultWithEntityName:(NSString*)entityName
                           Predicate:(NSPredicate*)predicate
                      SortDescriptors:(NSArray*)SortDescriptors
                          FetchLimit:(NSUInteger)FetchLimit;

-(NSArray*)fetchRequest:(NSFetchRequest*)fetchRequest withEntityName:(NSString *)entityName;
@end


