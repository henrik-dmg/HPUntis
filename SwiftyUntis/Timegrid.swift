//
//  Timegrid.swift
//  On Time(table)
//
//  Created by Henrik Panhans on 10.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Foundation
import SwiftyJSON

class Timegrid: NSObject, NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(numberOfDays, forKey: "numberOfDays")
        aCoder.encode(maxNumberOfPeriods, forKey: "maxNumberOfPeriods")
        aCoder.encode(earliestPeriodStart, forKey: "earliest")
        aCoder.encode(latestPeriodEnd, forKey: "latest")
        aCoder.encode(periods, forKey: "periods")
        aCoder.encode(periodStarts, forKey: "periodStarts")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.numberOfDays = aDecoder.decodeInteger(forKey: "numberOfDays")
        self.maxNumberOfPeriods = aDecoder.decodeInteger(forKey: "maxNumberOfPeriods")
        self.earliestPeriodStart = aDecoder.decodeInteger(forKey: "earliest")
        self.latestPeriodEnd = aDecoder.decodeInteger(forKey: "latest")
        self.periods = aDecoder.decodeObject(forKey: "periods") as! [Int:GridItem]
        self.periodStarts = aDecoder.decodeObject(forKey: "periodStarts") as! [Int:Int]
    }
    
    
    var numberOfDays = 1
    var maxNumberOfPeriods = 1
    var earliestPeriodStart: Int = 2400
    var latestPeriodEnd: Int = 2400
    var periods = [Int:GridItem]()
    var periodStarts = [Int:Int]()
    
    init(_ data: Data) {
        do {
            let json = try JSON(data: data)
            
            self.numberOfDays = (json["result"].array?.count)!
            
            var lastPeriod: GridItem?
            
            for i in 0...(json["result"].array![0]["timeUnits"].array!.count - 1) {
                let period = json["result"].array![0]["timeUnits"].array![i]
                let item = GridItem(period, previous: lastPeriod)
                lastPeriod = item
                periods[i] = item
                periodStarts[item.start] = (i + 1)
            }
            
            for day in json["result"].array! {
                if maxNumberOfPeriods <= day["timeUnits"].count {
                    maxNumberOfPeriods = day["timeUnits"].count
                }
                
                let firstPeriod = day["timeUnits"][0]["startTime"].int
                
                if firstPeriod! <= earliestPeriodStart {
                    earliestPeriodStart = firstPeriod!
                }
                
                let lastPeriodId = day["timeUnits"].count - 1
                let endTime = day["timeUnits"][lastPeriodId]["endTime"].int
                
                if endTime! >= latestPeriodEnd {
                    latestPeriodEnd = endTime!
                }
            }
        } catch let err {
            print(err.localizedDescription)
        }
    }
}

class GridItem: NSObject, NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(start, forKey: "start")
        aCoder.encode(end, forKey: "end")
        aCoder.encode(name, forKey: "name")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.start = aDecoder.decodeInteger(forKey: "start")
        self.end = aDecoder.decodeInteger(forKey: "end")
        self.name = aDecoder.decodeObject(forKey: "name") as! String
    }
    
    var start: Int = 0
    var end: Int = 0
    var name: String = ""
    
    init(_ json: JSON, previous: GridItem?) {
        start = json["startTime"].int!
        end = json["endTime"].int!
        name = json["name"].string!
    }
}
