//
//  Extensions.swift
//  On Timetable
//
//  Created by Henrik Panhans on 14.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}

extension Date {
    func dayOfMonth() -> Int {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.day, from: self)
        return weekOfYear
    }
    
    func time() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    func localizedDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale.current
        
        return formatter.string(from: self)
    }
    
    func toInt() -> Int {
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
    
    func week() -> Int {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.weekOfYear, .weekday], from: self)
        
        if comps.weekday == 1 {
            return (comps.weekOfYear! + 1)
        } else {
            return comps.weekOfYear!
        }
    }
    
    func daysInWeek() -> [Date] {
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

extension UILabel {
    func makeTextStrikeThrough() {
        if self.text != nil {
            let string =  NSMutableAttributedString(string: self.text!)
            string.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 2, range: NSMakeRange(0, string.length))
            self.attributedText = string
        }
    }
}

extension String {
    public func dateId() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd_HH:mm:ss"
        return formatter.string(from: date)
    }
}

extension Bool {
    func tapticFeedback() {
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

extension Int {
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
