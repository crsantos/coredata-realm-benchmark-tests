//
//  Person+CoreDataProperties.swift
//  CRCoreDataStack
//
//  Created by Carlos Santos on 06/02/16.
//  Copyright © 2016 crsantos. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Person {

    @NSManaged var name: String?
    @NSManaged var birthday: NSDate?
    @NSManaged var street: String?
    @NSManaged var country: String?
    @NSManaged var personId: NSNumber?

}
