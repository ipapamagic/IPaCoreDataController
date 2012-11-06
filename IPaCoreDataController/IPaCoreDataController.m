//
//  IPaCoreDataController.m
//
//  Created by IPaPa on 2011/6/8.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IPaCoreDataController.h"


@implementation IPaCoreDataController
{
	NSString *DBName;
}
#pragma mark - life cycle

- (IPaCoreDataController*) initDBWithName:(NSString*)dbName withParam:(NSDictionary*)params
{
    self = [super init];
	DBName = [dbName stringByAppendingString:@".sqlite"];
    
    
    //initial managed object model
    id value = params[IPaCoreDataPKey_SingleObjectModel];
    if (value) {
        NSString *modelPath = [[NSBundle mainBundle] pathForResource:value ofType:@"momd"];
        
        if (!modelPath) {
            modelPath = [[NSBundle mainBundle] pathForResource:value ofType:@"mom"];
        }
        
        
        // If path is nil, then NSURL or NSManagedObjectModel will throw an exception
        
        NSURL *momUrl = [NSURL fileURLWithPath:modelPath];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momUrl];
    }
    else {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }

    //initial persistentStoreCoordinator
    value = params[IPaCoreDataPKey_DBPath];
	NSString *storePath = (value)?value:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    storePath = [storePath stringByAppendingPathComponent:DBName];
	/*
	 Set up the store.
	 For the sake of illustration, provide a pre-populated default store.
	 */
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }   
	
	
	//initial managedObjectContext

    if (_persistentStoreCoordinator != nil) {
        _managedObjectContext = [NSManagedObjectContext new];
        [_managedObjectContext setPersistentStoreCoordinator: _persistentStoreCoordinator];
    }


	return self;
}



#pragma mark - core data stack

- (void)save
{
	NSError *error = nil;
	NSManagedObjectContext *context = self.managedObjectContext;
    if (context != nil)
    {
        if ([context hasChanges] && ![context save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (id) insertNewObjectForEntityForName:(NSString*)entityName;
{
	return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
	
}

- (void) deleteObject:(NSManagedObject *)object
{
	[_managedObjectContext deleteObject:object];
	[self save];
}
- (NSFetchedResultsController*)getFetchedResultsWithEntity:(NSString*)entityName 
												   SortKey:(NSString*)sortKey 
												 Ascending:(bool)ascending 
												 CacheName:(NSString*)cacheName
{	
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:_managedObjectContext];
	[fetchRequest setEntity:entity];
	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending];
	NSArray *sortDescriptors = @[sortDescriptor];
	[fetchRequest setSortDescriptors:sortDescriptors];        
	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:cacheName];
	
	//NSLog(@"%d",[aFetchedResultsController retainCount]);
	//return [aFetchedResultsController autorelease];
    return aFetchedResultsController;
}
-(NSArray*)fetchResultWithEntityName:(NSString*)entityName
                           Predicate:(NSPredicate*)predicate
                      SortDescriptors:(NSArray*)SortDescriptors
                          FetchLimit:(NSUInteger)FetchLimit
{

    NSManagedObjectContext *moc = [self managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:moc];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:SortDescriptors];
    [fetchRequest setFetchLimit:FetchLimit];
    
    return [moc executeFetchRequest:fetchRequest error:nil];
    
}

@end
