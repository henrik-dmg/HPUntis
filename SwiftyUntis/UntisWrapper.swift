//
//  UntisWrapper.swift
//  On Time(table)
//
//  Created by Henrik Panhans on 08.11.17.
//  Copyright © 2017 Henrik Panhans. All rights reserved.
//

import Alamofire
import SwiftyJSON

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
}

enum ErrorType: String {
    case invalidDate = "no allowed date";
    case unauthenticated = "not authenticated";
    case insufficientRights = "no right for"
}

class UntisWrapper {
    let defaults = UserDefaults.standard
    private let baseURL = "https://mese.webuntis.com/WebUntis/jsonrpc.do"
    var schoolName: String!
    var user: String!
    var password: String!
    var authenticated = false
    var login: Login?
    var lastImport = Date()
    var weekOnDisplay = Date().week()
    weak var delegate: UntisDelegate?
    var weeklySchedules = [Int:Schedule]() {
        didSet {
            delegate?.timegridDidRefresh()
        }
    }
    
    private var newestSchedule: Schedule? {
        didSet {
            weeklySchedules[newestSchedule!.week] = newestSchedule
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: newestSchedule!), forKey: "\(newestSchedule!.week)_schedule")
            
            delegate?.scheduleDidRefresh(for: newestSchedule!.week, old: oldValue, new: newestSchedule!)
        }
    }
    
    var currentDay = Date() {
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
    
    var sessionId: String? {
        didSet {
            authenticated = true
        }
    }
    
    var timeGrid: Timegrid? {
        didSet {
            delegate?.timegridDidRefresh()
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: timeGrid!), forKey: "timegrid")
            self.defaults.synchronize()
        }
    }
    
    var teachers = [Int:Teacher]() {
        didSet {
            delegate?.timegridDidRefresh()
        }
    }
    
    var students = [Int:Student]() {
        didSet {
            delegate?.timegridDidRefresh()
        }
    }
    
    var courses = [Int:Course]() {
        didSet {
            delegate?.timegridDidRefresh()
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: courses), forKey: "courses")
            self.defaults.synchronize()
        }
    }
    
    var subjects = [Int:Subject]() {
        didSet {
            delegate?.timegridDidRefresh()
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: subjects), forKey: "subjects")
            self.defaults.synchronize()
        }
    }
    
    var rooms = [Int:Room]() {
        didSet {
            delegate?.timegridDidRefresh()
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: rooms), forKey: "rooms")
            self.defaults.synchronize()
        }
    }
    
    func serializeDefaults() {
        if let grid = self.defaults.object(forKey: "timegrid") as? Data {
            self.timeGrid = NSKeyedUnarchiver.unarchiveObject(with: grid) as! Timegrid
            print("found timegrid")
        }
        
        if let subjects = self.defaults.object(forKey: "subjects") as? Data {
            self.subjects = NSKeyedUnarchiver.unarchiveObject(with: subjects) as! [Int:Subject]
            print("found subjects")
        }
        
        if let rooms = self.defaults.object(forKey: "rooms") as? Data {
            self.rooms = NSKeyedUnarchiver.unarchiveObject(with: rooms) as! [Int:Room]
            print("found rooms")
        }
        
        if let schedule = self.defaults.object(forKey: "\(currentDay.week())_schedule") as? Data {
            print("found a schedule")
            let sched = NSKeyedUnarchiver.unarchiveObject(with: schedule) as! Schedule
            weeklySchedules[sched.week] = sched
        }
        
        delegate?.timegridDidRefresh()
    }
    
    init(user: String, password: String, school: String) {
        self.user = user
        self.password = password
        self.schoolName = school
        
        self.serializeDefaults()
    }
    
    init(school: String) {
        self.schoolName = school
        
        self.serializeDefaults()
    }
    
    func authenticate(completion: ((Error?, String?) -> Void)?) {
        let parameters: [String:Any] = ["user": user!,
                                        "password": password!,
                                        "client": "CLIENT"]
        self.request(.authenticate, parameters: parameters) { (js, error) in
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
    
    func requestLastImport() {
        self.request(.lastImport, parameters: [:]) { (js, error) in
            if let json = js {
                if json["error"].null == nil {
                    print(json["error"]["message"].string)
                } else {
                    self.lastImport = Date(timeIntervalSince1970: Double(json["result"].int!))
                }
            }
        }
    }
    
    func logout() {
        self.request(.logout, parameters: [:], completion: nil)
    }
    
    func requestTimegrid(completion: ((Bool, String?) -> Void)?) {
        let url = buildUrl(sessionId)
        let parameters = constructParams("getTimegridUnits", params: [:])
        
        Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    self.timeGrid = Timegrid(data)
                    
                    do {
                        let json = try JSON(data: data)
                        
                        if json["error"].null == nil {
                            completion?(false, json["error"]["message"].string)
                        } else {
                            completion?(true, nil)
                        }
                    } catch let err {
                        completion?(false, err.localizedDescription)
                    }
                }
            case .failure(let error):
                print(error)
                completion?(false, error.localizedDescription)
            }
        }
    }
    
    func validateSchool(completion: ((Bool, String?) -> Void)?) {
        let url = buildUrl(sessionId)
        let jsonParams = constructParams("getTeachers", params: [:])
        
        Alamofire.request(url!, method: .post, parameters: jsonParams, encoding: JSONEncoding.default).validate().responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        
                        if json["error"]["message"].string == "not authenticated" {
                            completion?(true, "Confirmed school name")
                        } else {
                            completion?(false, json["error"]["message"].string)
                        }
                    } catch let err {
                        completion?(false, err.localizedDescription)
                    }
                }
            case .failure(let error):
                print(error)
                completion?(false, error.localizedDescription)
            }
        }
    }
    
    func requestCourses(completion: ((Bool, String?) -> Void)?) {
        let url = buildUrl(sessionId)
        let jsonParams = constructParams("getKlassen", params: [:])
        
        Alamofire.request(url!, method: .post, parameters: jsonParams, encoding: JSONEncoding.default).validate().responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        
                        if json["error"].null == nil {
                            completion?(false, json["error"]["message"].string)
                        } else {
                            DispatchQueue.global(qos: .utility).async {
                                for obj in json["result"].array! {
                                    let course = Course(obj)
                                    self.courses[course.id] = course
                                }
                            }
                            completion?(true, nil)
                        }
                    } catch let err {
                        completion?(false, err.localizedDescription)
                    }
                }
            case .failure(let error):
                print(error)
                completion?(false, error.localizedDescription)
            }
        }
    }
    
    func requestSubjects(completion: ((Bool, String?) -> Void)?) {
        let url = buildUrl(sessionId)
        let jsonParams = constructParams("getSubjects", params: [:])
        
        Alamofire.request(url!, method: .post, parameters: jsonParams, encoding: JSONEncoding.default).validate().responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let json = try JSON(data: data)
                        
                        if json["error"].null == nil {
                            completion?(false, json["error"]["message"].string)
                        } else {
                            DispatchQueue.global(qos: .utility).async {
                                for obj in json["result"].array! {
                                    let subject = Subject(obj)
                                    self.subjects[subject.id] = subject
                                }
                            }
                            completion?(true, nil)
                        }
                    } catch let err {
                        completion?(false, err.localizedDescription)
                    }
                }
            case .failure(let error):
                print(error)
                completion?(false, error.localizedDescription)
            }
        }
    }
    
    func requestStudents(completion: ((Error?, String?) -> Void)?) {
        self.request(.students, parameters: [:]) { (js, err) in
            if let json = js {
                if json["error"].null == nil {
                    completion?(err, json["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in json["result"].array! {
                            let student = Student(obj)
                            self.students[student.id] = student
                        }
                    }

                    completion?(err, nil)
                }
            } else { completion?(err, "No JSON parsed") }
        }
    }
    
    func requestTeachers(completion: ((Error?, String?) -> Void)?) {
        self.request(.teachers, parameters: [:]) { (json, err) in
            if let js = json {
                if js["error"].null == nil {
                    completion?(err, js["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in js["result"].array! {
                            let teacher = Teacher(obj)
                            self.teachers[teacher.id] = teacher
                        }
                    }
                    completion?(err, nil)
                }
            } else { completion?(err, "No JSON parsed") }
        }
    }
    
    func requestRooms(completion: ((Error?, String?) -> Void)?) {
        self.request(.rooms, parameters: [:]) { (json, err) in
            if let js = json {
                if js["error"].null == nil {
                    completion?(err, js["error"]["message"].string)
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        for obj in js["result"].array! {
                            let room = Room(obj)
                            self.rooms[room.id] = room
                        }
                    }
                    completion?(err, nil)
                }
            } else { completion?(err, "No JSON parsed") }
        }
    }
    
    func requestSchedule(for dates: [Date], feedback: Bool = false, completion: ((Error?, String?) -> Void)?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        print(formatter.string(from: dates[0]), "to", formatter.string(from: dates.last!))
        
        let params: [String:Any] = ["id": self.login?.personId ?? 0,
                                    "type": self.login?.personType ?? 5,
                                    "startDate": formatter.string(from: dates[0]),
                                    "endDate": formatter.string(from: dates.last!)]
        
        self.request(.schedule, parameters: params) { (json, err) in
            if let js = json {
                if feedback {
                    print("feedback is activated")
                    js["error"].isEmpty.tapticFeedback()
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
    }
    
    func request(_ function: Function, parameters: [String:Any], completion: ((JSON?, Error?) -> Void)?) {
        let url = buildUrl(sessionId)
        let jsonParams = constructParams(function.rawValue, params: parameters)
        Alamofire.request(url!, method: .post, parameters: jsonParams, encoding: JSONEncoding.default).responseJSON { (response) in
            switch response.result {
            case .success:
                do {
                    let json = try JSON(data: response.data!)
                    completion?(json, response.error)
                } catch let err {
                    completion?(nil, response.error)
                }
            case .failure:
                completion?(nil, response.error)
            }
        }
    }
    
    private func constructParams(_ function: String, params: [String:Any]) -> [String:Any] {
        let jsonParams: [String:Any] = ["id" : "\(arc4random())", "method": function, "params": params, "jsonrpc":"2.0"]
        
        return jsonParams
    }
    
    private func buildUrl(_ session: String?) -> URL? {
        guard var url = baseURL + "?school=\(schoolName!)" as? String else {
            print("school not set or not authenticated")
        }
        
        if session != nil {
            url = url + "&jsessionid=\(session!)"
        }
        
        let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        return URL(string: encodedUrl!)
    }
}

protocol UntisDelegate: class {
    func timegridDidRefresh()
    func scheduleDidRefresh(for week: Int, old: Schedule?, new: Schedule)
    func weekDidChange(old: Date, new: Date)
}

struct Login {
    var sessionId: String!
    var personType: Int!
    var personId: Int!
    var classId: Int!
    var request: Int!
    
    init(_ json: JSON) {
        sessionId = json["result"]["sessionId"].string
        personType = json["result"]["personType"].int
        personId = json["result"]["personId"].int
        classId = json["result"]["klasseId"].int
        request = json["id"].int
    }
}
