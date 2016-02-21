//
//  CRPerson.swift
//  CRCoreDataStack
//
//  Created by Carlos Santos on 07/02/16.
//  Copyright © 2016 crsantos. All rights reserved.
//

import Foundation
import RealmSwift

class CRPerson: Object {
    
    dynamic var name            = ""
    dynamic var birthday:NSDate = NSDate()
    dynamic var street:String   = ""
    dynamic var country:String  = ""
    dynamic var personId:String = NSUUID().UUIDString

    override static func primaryKey() -> String? {
        return "personId"
    }
}
