//
//  Teacher.swift
//  On Time(table)
//
//  Created by Henrik Panhans on 12.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Foundation
import SwiftyJSON

@objc(Teacher)
class Teacher: NSObject {
    var rawData: JSON
    var id: Int
    var short: String
    var firstName: String
    var lastName: String
    
    init(_ json: JSON) {
        rawData = json
        
        self.id = json["id"].int!
        self.short = json["name"].string!
        self.firstName = json["foreName"].string!
        self.lastName = json["longName"].string!
    }
}
