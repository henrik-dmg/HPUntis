//
//  Period.swift
//  On Time(table)
//
//  Created by Henrik Panhans on 12.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Foundation
import SwiftyJSON

enum PeriodState: String  {
    case active = "active";
    case cancelled = "cancelled";
    case irregular = "irregular";
    case undetermined = "";
}

@objc(Period)
class Period: NSObject, NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(teacherId, forKey: "teacher")
        aCoder.encode(roomId, forKey: "room")
        aCoder.encode(subjectId, forKey: "subject")
        aCoder.encode(startTime, forKey: "startTime")
        aCoder.encode(endTime, forKey: "endTime")
        aCoder.encode(date, forKey: "date")
        aCoder.encode(state.rawValue, forKey: "state")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.teacherId = aDecoder.decodeInteger(forKey: "teacher")
        self.roomId = aDecoder.decodeInteger(forKey: "room")
        self.subjectId = aDecoder.decodeInteger(forKey: "subject")
        self.startTime = aDecoder.decodeInteger(forKey: "startTime")
        self.endTime = aDecoder.decodeInteger(forKey: "endTime")
        self.date = aDecoder.decodeObject(forKey: "date") as! Date
        self.state = PeriodState(rawValue: (aDecoder.decodeObject(forKey: "state") as! String))!
    }
    
    var teacherId: Int
    var roomId: Int
    var subjectId: Int
    var startTime: Int
    var endTime: Int
    var date: Date
    var state: PeriodState
    
    init(teacher: Int, room: Int, subj: Int, start: Int, end: Int, date: Int, state: PeriodState) {
        self.teacherId = teacher
        self.roomId = room
        self.subjectId = subj
        self.startTime = start
        self.endTime = end
        self.state = state
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        self.date = formatter.date(from: "\(date)")!
    }
}
