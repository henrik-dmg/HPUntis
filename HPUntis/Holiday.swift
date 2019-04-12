//
//  Holiday.swift
//  SwiftyUntis
//
//  Created by Henrik Panhans on 20.12.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import UIKit
import SwiftyJSON

@objc(Holiday)
public class Holiday: NSObject, NSCoding {
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(startDate, forKey: "startDate")
        aCoder.encode(endDate, forKey: "endDate")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(longName, forKey: "longName")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeInteger(forKey: "teacher")
        self.startDate = aDecoder.decodeObject(forKey: "startDate") as! Date
        self.endDate = aDecoder.decodeObject(forKey: "endDate") as! Date
        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.longName = aDecoder.decodeObject(forKey: "longName") as! String
    }
    
    public var id: Int
    public var startDate: Date
    public var endDate: Date
    public var name: String
    public var longName: String
    
    public init(_ json: JSON) {
        self.id = json["id"].int!
        self.longName = json["longName"].string!
        self.name = json["name"].string!
        self.startDate = json["startDate"].int!.toDate()
        self.endDate = json["endDate"].int!.toDate()
    }
}

