//
//  Schedule.swift
//  On Time(table)
//
//  Created by Henrik Panhans on 12.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON

@objc(Schedule)
public class Schedule: NSObject, NSCoding {
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(timeGrid, forKey: "timeGrid")
        aCoder.encode(periods, forKey: "periods")
        aCoder.encode(week, forKey: "week")
        aCoder.encode(columnIds, forKey: "columnIds")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        timeGrid = aDecoder.decodeObject(forKey: "timeGrid") as! Timegrid
        
        if let loaded = aDecoder.decodeObject(forKey: "periods") as? [IndexPath:[Int:Period]] {
            self.periods = loaded
        }
        
        week = aDecoder.decodeInteger(forKey: "week")
        columnIds = aDecoder.decodeObject(forKey: "columnIds") as! [Int:Int]
    }
    
    // FIX BEFORE PRODUCTION
//    public func compareTo(_ other: Schedule) -> [IndexPath:Period] {
//        var changedPeriods = [IndexPath:Period]()
//        for period in self.periods {
//            if period.value.state != other.periods[period.key]?.state {
//                changedPeriods[period.key] = other.periods[period.key]!
//                print("found an anomaly at collumn and row \(period.key.section) - \(period.key.row)")
//            }
//        }
//        return changedPeriods
//    }
    
    public var timeGrid: Timegrid
    public var periods = [IndexPath:[Int:Period]]()
    public var week: Int
    private var columnIds = [Int:Int]()
    
    public init(_ json: JSON, grid: Timegrid, dateRange: [Date]) {
        timeGrid = grid
        
        week = dateRange[0].week()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        for i in 0...(dateRange.count - 1) {
            let date = dateRange[i]
            columnIds[Int(formatter.string(from: date))!] = i + 1
        }
        
        if let array = json["result"].array {
            for obj in array {
                var state = PeriodState.active
                
                if let code = obj["code"].string {
                    state = PeriodState(rawValue: code)!
                }
                
                let period = Period(teacher: obj["te"][0]["id"].intValue,
                                    room: obj["ro"][0]["id"].intValue,
                                    subj: obj["su"][0]["id"].intValue,
                                    start: obj["startTime"].int!,
                                    end: obj["startTime"].int!,
                                    date: obj["date"].int!,
                                    state: state)
                
                let index = IndexPath(row: grid.periodStarts[period.startTime]!,
                                      section: columnIds[period.date.toInt()]!)
                
                if let array = periods[index] {
                    periods[index]![period.subjectId] = period
                } else {
                    periods[index] = [period.subjectId:period]
                }
            }
        }
    }
}
