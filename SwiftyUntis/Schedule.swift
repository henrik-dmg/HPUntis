//
//  Schedule.swift
//  On Time(table)
//
//  Created by Henrik Panhans on 12.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Foundation
import SwiftyJSON

@objc(Schedule)
class Schedule: NSObject, NSCoding, Comparable {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(timeGrid, forKey: "timeGrid")
        aCoder.encode(periods, forKey: "periods")
        aCoder.encode(week, forKey: "week")
        aCoder.encode(columnIds, forKey: "columnIds")
    }
    
    required init?(coder aDecoder: NSCoder) {
        timeGrid = aDecoder.decodeObject(forKey: "timeGrid") as! Timegrid
        periods = aDecoder.decodeObject(forKey: "periods") as! [IndexPath:Period]
        week = aDecoder.decodeInteger(forKey: "week")
        columnIds = aDecoder.decodeObject(forKey: "columnIds") as! [Int:Int]
    }
    
    static func <(lhs: Schedule, rhs: Schedule) -> Bool {
        return false
    }
    
    static func ==(lhs: Schedule, rhs: Schedule) -> Bool {
        return NSDictionary(dictionary: lhs.periods).isEqual(to: rhs.periods)
    }
    
    var timeGrid: Timegrid
    var periods = [IndexPath:Period]()
    var week: Int
    private var columnIds = [Int:Int]()
    
    init(_ json: JSON, grid: Timegrid, dateRange: [Date]) {
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
                                      column: columnIds[period.date.toInt()]!)
                
                periods[index] = period
            }
        }
    }
}
