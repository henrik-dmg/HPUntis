//
//  Extensions.swift
//  On Timetable
//
//  Created by Henrik Panhans on 14.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Foundation
import UIKit

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

public extension Bool {
    public func tapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        
        switch self {
        case true:
            generator.notificationOccurred(.success)
        case false:
            generator.notificationOccurred(.error)
        }
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
        let intString = String(self)
        let formatter = DateFormatter()
        formatter.dateFormat = "Hmm"
        if let date = formatter.date(from: intString) {
            return date
        } else {
            formatter.dateFormat = "HHmm"
            if let date = formatter.date(from: intString) {
                return date
            }
            return Date(timeIntervalSince1970: 0)
        }
    }
}
