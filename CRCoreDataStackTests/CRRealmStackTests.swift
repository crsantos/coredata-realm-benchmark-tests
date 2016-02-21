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

            self.insert1MRecords()
            print("realm.testInsertMainThread: Inserted records.")
        }
    }

    func testInsertBackgroundThread() {

        self.measureBlock {

            let expectation = self.expectationWithDescription("realm.testInsertBackgroundThread")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

                self.insert1MRecords()
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

                let personIds = people.flatMap({ $0["personId"] })
                dispatch_async(dispatch_get_main_queue()) {

                    let aRealm = try! Realm()
                    let refetchedPeople = aRealm.objects(CRPerson).filter(NSPredicate(format: "personId IN %@",personIds))
                    print("realm.testFetchAllAsyncAndMoveToMainThread: Re-fetched on MT \(refetchedPeople.count) records")
                    expectation.fulfill()
                }
            }

            self.waitForExpectationsWithTimeout(Constants.maxNumberOfSecondsForTimeout, handler: { error -> Void in

                print("DONE realm.testFetchAllAsyncAndMoveToMainThread!")
            })
        }
    }

    func testDeleteBulk(){

        self.measureBlock() {

            self.deleteAll()
            print("realm.testDeleteBulk: Deleted all entries")
        }
    }

    // MARK: - Private

    func insert1MRecords(){

        let realm = try! Realm()
        realm.beginWrite()
        for i in 0...Constants.maxNumberOfEntities{

            let person = CRPerson()
            person.name = "TestPerson #\(i)"
            person.birthday = NSDate()
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

        self.insert1MRecords()
    }
    
    override func tearDown() {
        
        super.tearDown()
        self.deleteAll()
    }
}