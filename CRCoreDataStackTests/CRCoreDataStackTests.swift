//
//  CRCoreDataStackTests.swift
//  CRCoreDataStackTests
//
//  Created by Carlos Santos on 06/02/16.
//  Copyright © 2016 crsantos. All rights reserved.
//

import XCTest
import CoreData

@testable import CRCoreDataStack

/// CoreData tests
class CRCoreDataStackTests: XCTestCase {

    // MARK: - vars

    var managedObjectContext:NSManagedObjectContext!
    var childContext:NSManagedObjectContext!

    // MARK: - Tears

    override func setUp() {

        super.setUp()
        self.setUpInMemoryManagedObjectContext()

        print("cd.Setup CD stack");
    }

    override func tearDown() {

        // self.deleteAll()
        super.tearDown()
    }

    // MARK: - Insert Main thread

    func testInsertMainThread() {

        self.measureBlock {

            self.insert1MRecords()
        }
    }

    func testInsertBackgroundThread() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("cd.testInsertBackgroundThread")

            self.managedObjectContext.performBlock({ () -> Void in

                self.insert1MRecords()
                expectation.fulfill()
            })
        }
        self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

            print("DONE cd.testQueryAsynchronousFetch!")
        })
    }

    // MARK: - Async Fetch Request

    func testQueryAsynchronousFetch() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("coredata.testQueryAsynchronousFetch")

            let fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("Person", inManagedObjectContext:self.managedObjectContext)
            fetchRequest.entity = entity
            let asyncFetch = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) {
                (NSAsynchronousFetchResult result) -> Void in

                expectation.fulfill()
                print("cd.testQueryAsynchronousFetch: MT? \(NSThread.isMainThread())")
                if let theData = result.finalResult as? [Person] {
                    print("cd.testQueryAsynchronousFetch: Fetched \(theData.count)")
                }
            }

            do{
                try self.managedObjectContext.executeRequest(asyncFetch)
            } catch let error as NSError {

                print("cd.Could not fetch \(error), \(error.userInfo)")
            }

            self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

                print("DONE cd.testQueryAsynchronousFetch!")
            })
        }
    }

    // MARK: - Async Fetch Request and move to main thread

    func testQueryBackgroundAndMoveObjectsToMainThread() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("cd.testQueryBackgroundAndMoveObjectsToMainThread")

            let entity = NSEntityDescription.entityForName("Person", inManagedObjectContext:self.managedObjectContext)

            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = entity

            self.managedObjectContext.performBlock({ () -> Void in

                do {
                    let fetchResults = try self.managedObjectContext.executeFetchRequest(fetchRequest)

                    print("cd.testQueryBackgroundAndMoveObjectsToMainThread: MT? \(NSThread.isMainThread())")
                    print("cd.testQueryBackgroundAndMoveObjectsToMainThread: Fetched \(fetchResults.count)")

                    dispatch_async(dispatch_get_main_queue(), { () -> Void in

                        expectation.fulfill()
                    })

                } catch {
                    let saveError = error as NSError
                    expectation.fulfill()
                    print(saveError)
                }
            })

            self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

                print("DONE cd.testQueryBackgroundAndMoveObjectsToMainThread!")
            })
        }
    }

    func testQueryBackgroundAndMoveObjectsToMainConvertingThemInContexts() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("cd.testQueryBackgroundAndMoveObjectsToMainThread")

            let entity = NSEntityDescription.entityForName("Person", inManagedObjectContext:self.managedObjectContext)

            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = entity

            self.childContext.performBlock({ () -> Void in

                do {
                    let fetchResults = try self.childContext.executeFetchRequest(fetchRequest)

                    print("cd.testQueryBackgroundAndMoveObjectsToMainThread: MT? \(NSThread.isMainThread())")
                    print("cd.testQueryBackgroundAndMoveObjectsToMainThread: Fetched \(fetchResults.count)")

                    var objectIds:[AnyObject] = [];
                    for mObj in fetchResults{
                        if let managedObject = mObj as? NSManagedObject {
                            objectIds.append(managedObject.objectID)
                        }
                    }
                    var convertedObjects:[AnyObject] = []
                    for objId in objectIds{

                        if let objectId = objId as? NSManagedObjectID{
                            let converted = try self.managedObjectContext.existingObjectWithID(objectId)
                            convertedObjects.append(converted)
                        }

                    }
                    self.managedObjectContext.performBlock({ () -> Void in


                        // TODO: get converted objects
                        expectation.fulfill()
                    });

                } catch {
                    let saveError = error as NSError
                    expectation.fulfill()
                    print(saveError)
                }
            })
            
            self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in
                
                print("DONE cd.testQueryBackgroundAndMoveObjectsToMainThread!")
            })
        }
    }

    // MARK: - Batch Deletion
    
    func testDeleteBulk() {
        
        self.measureBlock {
            
            self.deleteAll()
            print("DONE cd.testDeleteBulk");
        }
    }

    // MARK: - Private

    func deleteAll(){

        let managedContext = self.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Person")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try managedContext.executeRequest(deleteRequest)
            try managedContext.save()
        } catch {
            print (error)
        }
    }

    // MARK: Insertions

    func insert1MRecords(){

        let entity =  NSEntityDescription.entityForName("Person",
            inManagedObjectContext:self.managedObjectContext)

        for i in 0...Constants.maxNumberOfEntities{

            let person:NSManagedObject = NSManagedObject(
                entity: entity!,
                insertIntoManagedObjectContext: self.managedObjectContext)

            person.setValue("random name", forKey: "name")
            person.setValue(i, forKey: "personId")
            person.setValue("PT", forKey: "country")
            person.setValue("Rua Augusta", forKey: "street")
            person.setValue(NSDate(), forKey: "birthday")
        }

        do {
            try self.managedObjectContext.save()
            print("cd.Persisted 1M objects")

        } catch let error as NSError  {
            print("cd.Could not save \(error), \(error.userInfo)")
        }
    }

    // MARK: CD stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "info.crsantos.CRCoreDataStack" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()


    func setUpInMemoryManagedObjectContext() {

        let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle.mainBundle()])!
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CRCoreDataStackTests.sqlite")
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(
                NSSQLiteStoreType,
                configuration: nil,
                URL: url,
                options: nil)
        } catch {
            print("cd.Adding persistent store coordinator failed")
        }
        let managedObjectContext = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType);
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        self.managedObjectContext = managedObjectContext;
        self.childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.childContext.parentContext = self.managedObjectContext;
    }
}