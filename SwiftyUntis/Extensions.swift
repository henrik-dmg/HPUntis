//
//  Extensions.swift
//  On Timetable
//
//  Created by Henrik Panhans on 14.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Foundation
import UIKit
import WatchKit

public extension Untis {
    func clearAll() {
        self.logout()
        
        self.weeklySchedules.removeAll()
        self.courses.removeAll()
        self.subjects.removeAll()
        self.teachers.removeAll()
        self.students.removeAll()
        self.holidays.removeAll()
        self.rooms.removeAll()
        
        let ids = ["timegrid", "subjects", "rooms", "schedules", "holidays", "fakeSchedules"]
        
        for id in ids {
            UserDefaults.standard.set(nil, forKey: id)
        }
    }
    
    func loadFromDisk() {
        if let grid = UserDefaults.standard.object(forKey: "timegrid") as? Data {
            self.timeGrid = NSKeyedUnarchiver.unarchiveObject(with: grid) as? Timegrid
            print("found timegrid")
        }
        
        if let subjects = UserDefaults.standard.object(forKey: "subjects") as? Data {
            self.subjects = NSKeyedUnarchiver.unarchiveObject(with: subjects) as! [Int:Subject]
            print("found subjects")
        }
        
        if let rooms = UserDefaults.standard.object(forKey: "rooms") as? Data {
            self.rooms = NSKeyedUnarchiver.unarchiveObject(with: rooms) as! [Int:Room]
            print("found rooms")
        }
        
        if let schedules = UserDefaults.standard.object(forKey: "schedules") as? Data {
            print("found schedules")
            let sched = NSKeyedUnarchiver.unarchiveObject(with: schedules) as! [Int:Schedule]
            self.weeklySchedules = sched
        }
        
        if let holidays = UserDefaults.standard.object(forKey: "holidays") as? Data {
            print("found holidays")
            let holid = NSKeyedUnarchiver.unarchiveObject(with: holidays) as! [Int:Holiday]
            self.holidays = holid
        }
    }
    
    var allHolidays: [String] {
        var arr = [String]()
        
        for holiday in self.holidays {
            arr.append(contentsOf: holiday.value.datesInBetween)
        }
        
        return arr
    }
}

public extension Holiday {
    var datesInBetween: [String] {
        var dates = [String]()
        var date = self.startDate
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM/yyyy"
        
        while date <= self.endDate {
            dates.append(fmt.string(from: date))
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
        
        return dates
    }
}

public extension Bool {
    public func tapticFeedback() {
        #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            
            switch self {
            case true:
                generator.notificationOccurred(.success)
            case false:
                generator.notificationOccurred(.error)
            }
        #elseif os(watchOS)
            switch self {
            case true:
                WKInterfaceDevice.current().play(.success)
            case false:
                WKInterfaceDevice.current().play(.failure)
            }
        #else
            println("OMG, it's that mythical new Apple product!!!")
        #endif
    }
}

public extension UIColor {
    convenience init(hexString: String) {
        let hexString: String = hexString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        let scanner            = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func hexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
}

public extension Date {
    public func toInt() -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let int = Int(formatter.string(from: self))!
        
        return int
    }
    
    public init?(string: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        let date = formatter.date(from: string)
        
        self = date!
        return
    }
    
    public func week() -> Int {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.weekOfYear, .weekday], from: self)
        
        if comps.weekday == 1 {
            return (comps.weekOfYear! + 1)
        } else {
            return comps.weekOfYear!
        }
    }
    
    public func daysInWeek() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: self)
        let dayOfWeek = calendar.component(.weekday, from: today)
        let weekdays = calendar.range(of: .weekday, in: .weekOfYear, for: today)!
        let days = (weekdays.lowerBound ..< weekdays.upperBound)
            .flatMap { calendar.date(byAdding: .day, value: $0 - dayOfWeek, to: today) }
            .filter { !calendar.isDateInWeekend($0) }
        return days
    }
}

public extension Int {
    public func toWeekdays(year: Int) -> [Date] {
        var c = DateComponents()
        c.weekOfYear = self
        c.year = year
        // Get NSDate given the above date components
        if let dates = Calendar(identifier: .gregorian).date(from: c)?.daysInWeek() {
            return dates
        } else {
            return []
        }
    }
    
    public func toDate() -> Date {
        let possibleFormats = ["Hmm", "HHmm", "yyyyMMdd"]
        
        let intString = String(self)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        
        for format in possibleFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: intString) {
                return date
            }
        }
        
        return Date(timeIntervalSince1970: 0)
    }
}
