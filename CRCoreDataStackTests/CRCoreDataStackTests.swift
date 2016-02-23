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

    // MARK: - Insert Main thread

    func testInsertMainThread() {

        self.measureBlock {

            self.insertBulkRecords(self.managedObjectContext)
            print("DONE cd.testInsertMainThread: Inserted records.")
        }
    }

    func testInsertBackgroundThread() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("cd.testInsertBackgroundThread")

            self.childContext.performBlock({ () -> Void in
                print("cd.testInsertBackgroundThread: MT? \(NSThread.isMainThread())")
                self.insertBulkRecords(self.childContext)
                expectation.fulfill()
            })
        }
        self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

            print("DONE cd.testInsertBackgroundThread!")
        })
    }

    // MARK: - Async Fetch Request

    func testQueryAsynchronousFetch() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("cd.testQueryAsynchronousFetch")

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

            do {
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

    func testFetchAllAsyncAndMoveToMainThread() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("cd.testFetchAllAsyncAndMoveToMainThread")

            let fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("Person", inManagedObjectContext:self.managedObjectContext)
            fetchRequest.entity = entity
            let asyncFetch = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) {
                (NSAsynchronousFetchResult result) -> Void in
                if let theData = result.finalResult as? [Person] {

                    print("cd.testFetchAllAsyncAndMoveToMainThread: Fetched \(theData.count)")
                    print("cd.testFetchAllAsyncAndMoveToMainThread: MT? \(NSThread.isMainThread())")
                    do {
                        var objectIds:[AnyObject] = []
                        for mObj in theData{
                            if let managedObject:NSManagedObject = mObj {
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

                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            print("cd.testFetchAllAsyncAndMoveToMainThread Converted: \(convertedObjects.count) objects to main context")
                            expectation.fulfill()
                        })

                    } catch {
                        let saveError = error as NSError
                        print(saveError)
                    }
                }
            }

            do {
                try self.managedObjectContext.executeRequest(asyncFetch)
            } catch let error as NSError {

                print("cd.Could not fetch \(error), \(error.userInfo)")
            }
        }
        self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

            print("DONE cd.testFetchAllAsyncAndMoveToMainThread!")
        })
    }

    func testBatchUpdate(){

        self.measureBlock {

            let expectation = self.expectationWithDescription("cd.testBatchUpdate")

            let entity = NSEntityDescription.entityForName("Person", inManagedObjectContext:self.childContext)
            let req = NSBatchUpdateRequest.init(entity: entity!)
            req.propertiesToUpdate = ["street": "Rua..."]
            req.resultType = .StatusOnlyResultType;

            self.childContext .performBlock({ () -> Void in

                do {
                    try self.childContext.executeRequest(req)
                    expectation.fulfill()

                } catch let error as NSError {

                    print("cd.testBatchUpdate Could not update \(error), \(error.userInfo)")
                    expectation.fulfill()
                }
            })
        }
        self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

            print("DONE cd.testFetchAllAsyncAndMoveToMainThread!")
        })
    }
    
    // MARK: - Batch Deletion
    
    func testDeleteBulk() {
        
        self.measureBlock {
            
            self.deleteAll()
            print("DONE cd.testDeleteBulk")
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

    func insertBulkRecords(context:NSManagedObjectContext){

        let entity =  NSEntityDescription.entityForName("Person",
            inManagedObjectContext:context)

        let birthdate:NSDate = NSDate()
        for i in 0...Constants.maxNumberOfEntities{

            let person:NSManagedObject = NSManagedObject(
                entity: entity!,
                insertIntoManagedObjectContext: context)

            person.setValue("random name #\(i)", forKey: "name")
            person.setValue(i, forKey: "personId")
            person.setValue("PT", forKey: "country")
            person.setValue("Rua Augusta", forKey: "street")
            person.setValue(birthdate, forKey: "birthday")
        }

        do {

            try context.save()

            if let parentContext = context.parentContext{

                try parentContext.save(); // persist on parent
            }
            print("cd.Persisted 1M objects")

        } catch let error as NSError  {
            print("cd.Could not save \(error), \(error.userInfo)")
        }
    }

    // MARK: - Setup

    override func setUp() {

        super.setUp()
        self.setUpInMemoryManagedObjectContext()

        self.insertBulkRecords(self.managedObjectContext)
        print("cd.Setup CD stack")
    }

    override func tearDown() {

        super.tearDown()
        self.deleteAll()
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


        self.managedObjectContext = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        self.childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.childContext.parentContext = self.managedObjectContext
    }
}
