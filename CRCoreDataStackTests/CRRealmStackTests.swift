//
//  CRRealmStackTests.swift
//  CRCoreDataStack
//
//  Created by Carlos Santos on 07/02/16.
//  Copyright © 2016 crsantos. All rights reserved.
//

import UIKit
import XCTest
import RealmSwift

@testable import CRCoreDataStack

/// Realm tests
class CRRealmStackTests : XCTestCase {

    func testInsertMainThread() {

        self.measureBlock() {

            self.insertBulkRecords()
            print("DONE realm.testInsertMainThread: Inserted records.")
        }
    }

    func testInsertBackgroundThread() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("realm.testInsertBackgroundThread")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

                self.insertBulkRecords()
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

            print("DONE realm.testInsertBackgroundThread!")
        })
    }

    func testQueryAsynchronousFetch(){

        self.measureBlock() {

            let expectation = self.expectationWithDescription("realm.testQueryAsynchronousFetch")

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

                    let aRealm = try! Realm()
                    let people = aRealm.objects(CRPerson)

                    print("realm.testQueryAsynchronousFetch: Fetched \(people.count) records")
                    expectation.fulfill()
                }

            self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

                print("DONE realm.testQueryAsynchronousFetch!")
            })
        }
    }

    func testFetchAllAsyncAndMoveToMainThread(){

        self.measureBlock() {

            let expectation = self.expectationWithDescription("realm.testFetchAllAsync")

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

                let aRealm = try! Realm()
                let people = aRealm.objects(CRPerson)

                print("realm.testFetchAllAsyncAndMoveToMainThread: Fetched \(people.count) records")

                // optional fetch via primary key: this is the bottleneck here, not the query
                // let personIds = people.flatMap({ $0["personId"] })
                dispatch_async(dispatch_get_main_queue()) {

                    let aRealm = try! Realm()
                    // let refetchedPeople = aRealm.objects(CRPerson).filter(NSPredicate(format: "personId IN %@",personIds))
                    let refetchedPeople = aRealm.objects(CRPerson)
                    print("realm.testFetchAllAsyncAndMoveToMainThread: Re-fetched on MT \(refetchedPeople.count) records")
                    expectation.fulfill()
                }
            }

            self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

                print("DONE realm.testFetchAllAsyncAndMoveToMainThread!")
            })
        }
    }

    func testBatchUpdate(){

        self.measureBlock() {

            let expectation = self.expectationWithDescription("realm.testBatchUpdate")

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

                let realm = try! Realm()
                let people = realm.objects(CRPerson)

                realm.beginWrite()
                people.setValue("Rua...", forKey: "street")
                try! realm.commitWrite()
                expectation.fulfill()
            }
        }

        self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

            print("DONE realm.testBatchUpdate!")
        })
    }

    func testDeleteBulk(){

        self.measureBlock() {

            self.deleteAll()
            print("realm.testDeleteBulk: Deleted all entries")
        }
    }

    // MARK: - Private

    func insertBulkRecords(){

        let birthdate:NSDate = NSDate()
        let realm = try! Realm()
        realm.beginWrite()
        for i in 0...Constants.maxNumberOfEntities{

            let person = CRPerson()
            person.name = "random name #\(i)"
            person.birthday = birthdate
            person.country = "PT"
            person.street = "Rua Augusta"
            realm.add(person)
        }
        try! realm.commitWrite()
    }

    func deleteAll(){

        let realm = try! Realm()
        realm.beginWrite()
        realm.deleteAll()
        try! realm.commitWrite()
    }

    // MARK: Setup

    override func setUp() {

        super.setUp()
        self.insertBulkRecords()
    }
    
    override func tearDown() {
        
        super.tearDown()
        self.deleteAll()
    }
}
