//
//  Untis.swift
//  On Time(table)
//
//  Created by Henrik Panhans on 08.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Alamofire
import SwiftyJSON

public enum ErrorType: String {
    case invalidDate = "no allowed date";
    case unauthenticated = "not authenticated";
    case insufficientRights = "no right for"
}

public enum PostMethod {
    case alamofire;
    case nsurlsession;
}

public class Untis {
    enum Function: String {
        case authenticate = "authenticate";
        case logout = "logout";
        case lastImport = "getLatestImportTime";
        case gridUnits = "getTimegridUnits";
        case teachers = "getTeachers";
        case students = "getStudents";
        case courses = "getKlassen";
        case subjects = "getSubjects";
        case schedule = "getTimetable";
        case rooms = "getRooms";
        case holidays = "getHolidays";
    }
    
    public var baseURL = "https://mese.webuntis.com/WebUntis/jsonrpc.do"
    public var schoolName: String?
    public var user: String?
    public var password: String?
    public var authenticated = false
    public var login: Login?
    public var lastImport = Date()
    public var weekOnDisplay = Date().week()
    public weak var delegate: UntisDelegate?
    
    public var weeklySchedules = [Int:Schedule]() {
        didSet {
            delegate?.objectChanged(weeklySchedules as NSObject)
        }
    }
    
    public var newestSchedule: Schedule? {
        didSet {
            weeklySchedules[newestSchedule!.week] = newestSchedule
            delegate?.scheduleDidRefresh(for: newestSchedule!.week, old: oldValue, new: newestSchedule!)
        }
    }
    
    public var currentDay = Date() {
        didSet {
            weekOnDisplay = currentDay.week()
            
            if self.weeklySchedules[currentDay.week()] == nil {
                self.requestSchedule(for: currentDay.daysInWeek(), completion: nil)
                self.requestSchedule(for: currentDay.addingTimeInterval(60*60*24*7).daysInWeek(), completion: nil)
                self.requestSchedule(for: currentDay.addingTimeInterval(-60*60*24*7).daysInWeek(), completion: nil)
            }
            
            self.delegate?.weekDidChange(old: oldValue, new: self.currentDay)
        }
    }
    
    public var sessionId: String? {
        didSet {
            authenticated = true
        }
    }
    
    public var timeGrid: Timegrid? {
        didSet {
            delegate?.timegridDidRefresh()
            delegate?.objectChanged(timeGrid!)
        }
    }
    
    public var teachers = [Int:Teacher]() {
        didSet {
            //delegate?.timegridDidRefresh()
        }
    }
    
    public var students = [Int:Student]() {
        didSet {
            //delegate?.timegridDidRefresh()
        }
    }
    
    public var courses = [Int:Course]() {
        didSet {
            delegate?.objectChanged(courses as NSObject)
        }
    }
    
    public var subjects = [Int:Subject]() {
        didSet {
            delegate?.objectChanged(subjects as NSObject)
        }
    }
    
    public var rooms = [Int:Room]() {
        didSet {
            delegate?.objectChanged(rooms as NSObject)
        }
    }
    
    public var holidays = [Int:Holiday]() {
        didSet {
            delegate?.objectChanged(holidays as NSObject)
        }
    }
    
    public init?(user: String, password: String, school: String, url: String) {
        self.user = user
        self.password = password
        self.schoolName = school
        self.baseURL = url
    }
    
    
    public init?(school: String) {
        self.schoolName = school
    }
    
    public init() {
        self.user = "Unknown User"
        self.password = "PseudoPassword"
        self.schoolName = "Unknown School"
        self.baseURL = "https://mese.webuntis.com/WebUntis/jsonrpc.do"
    }
    
    
    public func requestAll(method: PostMethod = .alamofire) {
        if authenticated {
            print("Requesting all")
            self.requestLastImport()
            self.requestTimegrid(completion: nil)
            self.requestRooms(completion: nil)
            self.requestHolidays(completion: nil)
            self.requestSubjects(completion: nil)
            self.requestCourses(completion: nil)
            self.requestStudents(completion: nil)
            self.requestTeachers(completion: nil)
        } else {
            print("Error: Untis user is not authenticated")
        }
    }
    
    // FIX BEFORE PRODUCTION
//    public func compare(old schedule: Schedule, new: Schedule) -> [IndexPath:Period] {
//        var changedPeriods = [IndexPath:Period]()
//
//        for period in new.periods {
//            let newPeriod = period.value
//
//            if let oldPeriod = schedule.periods[period.key], oldPeriod.state != newPeriod.state {
//                changedPeriods[period.key] = newPeriod
//            }
//        }
//
//        return changedPeriods
//    }
    
    public func authenticate(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        let parameters: [String:Any] = ["user": user!,
                                        "password": password!,
                                        "client": "CLIENT"]
        self.request(.authenticate, method: method, parameters: parameters) { (js, error) in
            if let json = js {
                if json["error"].null == nil {
                    self.authenticated = false
                    completion?(error, json["error"]["message"].string)
                } else {
                    self.sessionId = json["result"]["sessionId"].string
                    self.login = Login(json)
                    self.authenticated = true
                    completion?(error, nil)
                }
            } else {
                completion?(error, nil)
            }
        }
    }
    
    public func requestLastImport(method: PostMethod = .alamofire) {
        self.request(.lastImport, method: method, parameters: [:]) { (js, error) in
            if let json = js {
                if json["error"].null != nil {
                    self.lastImport = Date(timeIntervalSince1970: Double(json["result"].int!))
                } else {
                    print("Could not get last import date. Reason: \(json["error"]["message"].string!)")
                }
            }
        }
    }
    
    public func logout(method: PostMethod = .alamofire) {
        self.request(.logout, method: method, parameters: [:], completion: nil)
    }
    
    public func requestTimegrid(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        print("Refreshing Timegrid")
        self.request(.gridUnits, method: method, parameters: [:]) { (js, error) in
            if let json = js {
                if json["error"].null == nil {
                    completion?(error, json["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        self.timeGrid = Timegrid(json)
                        completion?(error, nil)
                    }
                }
            } else {
                completion?(error, nil)
            }
        }
    }
    
    public func validateSchool(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        self.request(.teachers, method: method, parameters: [:]) { (js, error) in
            if let json = js {
                if json["error"]["message"].string == "not authenticated" || json["error"]["message"].string == "no right for getTeachers()" {
                    completion?(nil, "Confirmed school name")
                } else {
                    completion?(error, json["error"]["message"].string)
                }
            } else {
                completion?(error, nil)
            }
        }
    }
    
    public func requestCourses(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        self.request(.courses, method: method, parameters: [:]) { (js, error) in
            if let json = js {
                if json["error"].null == nil {
                    completion?(error, json["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in json["result"].array! {
                            let course = Course(obj)
                            self.courses[course.id] = course
                        }
                        completion?(error, nil)
                    }
                }
            } else {
                completion?(error, nil)
            }
        }
    }
    
    public func requestSubjects(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        self.request(.subjects, method: method, parameters: [:]) { (js, error) in
            if let json = js {
                if json["error"].null == nil {
                    completion?(error, json["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in json["result"].array! {
                            let subject = Subject(obj)
                            self.subjects[subject.id] = subject
                        }
                        completion?(error, nil)
                    }
                    
                }
            } else {
                completion?(error, nil)
            }
        }
    }
    
    public func requestStudents(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        self.request(.students, method: method, parameters: [:]) { (js, err) in
            if let json = js {
                if json["error"].null == nil {
                    completion?(err, json["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in json["result"].array! {
                            let student = Student(obj)
                            self.students[student.id] = student
                        }
                        completion?(err, nil)
                    }
                }
            } else { completion?(err, "No JSON parsed") }
        }
    }
    
    public func requestTeachers(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        self.request(.teachers, method: method, parameters: [:]) { (json, err) in
            if let js = json {
                if js["error"].null == nil {
                    completion?(err, js["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in js["result"].array! {
                            let teacher = Teacher(obj)
                            self.teachers[teacher.id] = teacher
                        }
                        completion?(err, nil)
                    }
                }
            } else { completion?(err, "No JSON parsed") }
        }
    }
    
    public func requestRooms(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        self.request(.rooms, method: method, parameters: [:]) { (json, error) in
            if let js = json {
                if js["error"].null == nil {
                    completion?(error, js["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in js["result"].array! {
                            let room = Room(obj)
                            self.rooms[room.id] = room
                        }
                        completion?(error, nil)
                    }
                }
            } else { completion?(error, nil) }
        }
    }
    
    public func requestHolidays(method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        self.request(.holidays, method: method, parameters: [:]) { (json, error) in
            if let js = json {
                if js["error"].null == nil {
                    completion?(error, js["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in js["result"].array! {
                            let holiday = Holiday(obj)
                            self.holidays[holiday.id] = holiday
                        }
                        completion?(error, nil)
                    }
                }
            } else { completion?(error, nil) }
        }
    }
    
    public func requestSchedule(for dates: [Date], feedback: Bool = false, method: PostMethod = .alamofire, completion: ((Error?, String?) -> Void)?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        if let login = self.login {
            let params: [String:Any] = ["id": login.personId,
                                        "type": login.personType,
                                        "startDate": formatter.string(from: dates[0]),
                                        "endDate": formatter.string(from: dates.last!)]
            
            if self.timeGrid != nil {
                self.request(.schedule, method: method, parameters: params) { (json, err) in
                    if let js = json {
                        if feedback {
                            DispatchQueue.main.async {
                                js["error"].isEmpty.tapticFeedback()
                            }
                        }
                        
                        if js["error"].null == nil {
                            completion?(err, js["error"]["message"].string)
                        } else {
                            DispatchQueue.global(qos: .userInteractive).async {
                                let schedule = Schedule(js, grid: self.timeGrid!, dateRange: dates)
                                
                                self.newestSchedule = schedule
                            }
                            completion?(err, nil)
                        }
                    } else {
                        completion?(err, nil)
                    }
                }
            } else {
                print("Error: Empty Timegrid")
            }
        } else {
            delegate?.requestFailed()
            print("Error: Untis user not authenticated")
        }
    }
    
    private func request(_ function: Function, method: PostMethod, parameters: [String:Any], completion: ((JSON?, Error?) -> Void)?) {
        let url = buildUrl(sessionId)
        let jsonParams = constructParams(function.rawValue, params: parameters)
        
        switch method {
        case .alamofire:
            Alamofire.request(url!, method: .post, parameters: jsonParams, encoding: JSONEncoding.default).responseJSON { (response) in
                switch response.result {
                case .success:
                    do {
                        let json = try JSON(data: response.data!)
                        completion?(json, response.error)
                    } catch {
                        completion?(nil, response.error)
                    }
                case .failure:
                    completion?(nil, response.error)
                }
            }
        case .nsurlsession:
            if let jsonData = try? JSONSerialization.data(withJSONObject: jsonParams, options: .prettyPrinted) {
                let request = NSMutableURLRequest(url: url!)
                request.httpMethod = "POST"
                
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                    if let goodData = data {
                        if let json = try? JSON(data: goodData) {
                            print(json)
                            completion?(json, error)
                        } else {
                            completion?(nil, error)
                        }
                    } else {
                        
                        completion?(nil, error)
                    }
                }
                task.resume()
            }
        }
    }
    
    private func constructParams(_ function: String, params: [String:Any]) -> [String:Any] {
        let jsonParams: [String:Any] = ["id" : "\(arc4random())", "method": function, "params": params, "jsonrpc":"2.0"]
        
        return jsonParams
    }
    
    private func buildUrl(_ session: String?) -> URL? {
        if schoolName != nil {
            var url = baseURL + "?school=\(schoolName!)"
            
            if session != nil {
                url = url + "&jsessionid=\(session!)"
            }
            
            let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            return URL(string: encodedUrl!)
        } else {
            return nil
        }
    }
}

public protocol UntisDelegate: class {
    func timegridDidRefresh()
    func scheduleDidRefresh(for week: Int, old: Schedule?, new: Schedule)
    func weekDidChange(old: Date, new: Date)
    func objectChanged(_ object: NSObject)
    func requestFailed()
}

public struct Login {
    public var sessionId: String
    public var personType: Int
    public var personId: Int
    public var classId: Int
    public var request: Int?
    
    public init(_ json: JSON) {
        sessionId = json["result"]["sessionId"].string!
        personType = json["result"]["personType"].int!
        personId = json["result"]["personId"].int!
        classId = json["result"]["klasseId"].int!
        request = json["id"].int
    }
}
