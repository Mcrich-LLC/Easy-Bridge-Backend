//
//  Bridge Fetch.swift
//  
//
//  Created by Morris Richman on 8/17/22.
//

import Foundation
import Vapor
import VaporCron
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import FluentKit
import FCM
import FeedKit

struct BridgeCheckStreamEveryMinuteJob: VaporCronSchedulable {
    typealias T = Void
    
    static var expression: String { "*/1 * * * * *" } // every second

    static func task(on application: Application) -> EventLoopFuture<Void> {
        print("ComplexJob start")
        BridgeFetch.streamTweets(db: application.db)
        return application.eventLoopGroup.future().always { _ in
            print("ComplexJob fired")
        }
    }
}
struct BridgeFetch {
    private static func getPushNotificationPreferences(path: String, completion: @escaping (Preferences) -> Void) {
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/easy-bridge-tracker/databases/(default)/documents/\(path)?key=\(Secrets.firebaseWebAuthToken)") else { return }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
            if let error = error {
                print("Error making Post request: \(error.localizedDescription)")
                return
            }
            
            if let responseCode = (response as? HTTPURLResponse)?.statusCode, let responseData = responseData {
                guard responseCode == 200 else {
                    print("Invalid Firebase response code: \(responseCode)")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let eventResponse = try decoder.decode(PrefResponse.self, from: responseData)
                    
                    // Use the decoded data as required
                    completion(eventResponse.fields)
                } catch {
                    print(error)
                }
            }
        }
        task.resume()
    }

    private static func getPushNotificationList(bridge: BridgeResponse, completion: @escaping (Preferences) -> Void) {
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/easy-bridge-tracker/databases/(default)/documents/Directory/\(bridge.id)?key=\(Secrets.firebaseWebAuthToken)") else {
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
            if let error = error {
                print("Error making Post request: \(error.localizedDescription)")
                return
            }
            
            if let responseCode = (response as? HTTPURLResponse)?.statusCode, let responseData = responseData {
                guard responseCode == 200 else {
                    print("Invalid Firebase response code: \(responseCode)")
                    return
                }
                
                do {
                    let jsonDecoder = JSONDecoder()
                        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                    let directory = try jsonDecoder.decode(DirectoryResponse.self, from: responseData)
                    var sentNotificationIds: [String] = []
                    for path in directory.fields.subscribedUsers.arrayValue.values.map({ $0.stringValue }) where !sentNotificationIds.contains(path) {
                        getPushNotificationPreferences(path: path, completion: completion)
                        sentNotificationIds.append(path)
                    }
                } catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    private static func convertUTCToPDT(utcDate: Date) -> Date {
        let timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let calendar = Calendar.current
        return utcDate.addingTimeInterval(TimeInterval(timeZone.secondsFromGMT(for: utcDate)))
    }

    private static func currentTimeIsBetween(startTime: String, endTime: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles") // Use the Olson identifier for PDT
        
        let currentDate = Date()
        let currentTimeString = dateFormatter.string(from: currentDate)
        
        guard let startTimeDate = dateFormatter.date(from: startTime),
              let endTimeDate = dateFormatter.date(from: endTime),
              let currentTimeDate = dateFormatter.date(from: currentTimeString) else {
            return false
        }
        
        let convertedStartTime = convertUTCToPDT(utcDate: startTimeDate)
        let convertedEndTime = convertUTCToPDT(utcDate: endTimeDate)
        let convertedCurrentTime = convertUTCToPDT(utcDate: currentTimeDate)
        
        print("Start Time = \(convertedStartTime)")
        print("End Time = \(convertedEndTime)")
        print("DateInterval(start: start, end: end) = \(DateInterval(start: convertedStartTime, end: convertedEndTime))")
        
        return convertedStartTime <= convertedCurrentTime && convertedCurrentTime <= convertedEndTime
    }

    
    static func postBridgeNotification(bridge: Bridge, bridgeDetails: BridgeResponse) {
        getPushNotificationList(bridge: bridgeDetails) { pref in
            let bridgeIds = pref.bridgeIds.arrayValue.asStrings()
            let days = pref.days.arrayValue.asStrings()
            
            let startTime = pref.startTime.stringValue
            let endTime = pref.endTime.stringValue
            
            print("***SEND NOTIFICATION***\n\n")
            print("bridgeId = \(bridgeDetails.id)")
            print("day = \(Day.currentDay()!)")
            print("days.contains(day.rawValue) = \(days.contains(Day.currentDay()!.rawValue))")
            print("currentTimeIsBetween(startTime: pref.startTime.stringValue, endTime: pref.endTime.stringValue = \(currentTimeIsBetween(startTime: startTime, endTime: endTime))")
            print("Is current time between \(startTime) and \(endTime): \(currentTimeIsBetween(startTime: startTime, endTime: endTime))")
            print("pref.isAllDay.booleanValue = \(pref.isAllDay.booleanValue)")
            print("bridgeIds.contains(bridgeDetails.id) = \(bridgeIds.contains(bridgeDetails.id))")
            print("pref.isActive.booleanValue = \(pref.isActive.booleanValue)")
//            print("pref.isBeta.booleanValue == (Utilities.environment == .testing || Utilities.environment != .development) = \(pref.isBeta.booleanValue == (Utilities.environment == .testing || Utilities.environment = .development))")
            guard let day = Day.currentDay(),
                  days.contains(day.rawValue),
                  (currentTimeIsBetween(startTime: startTime, endTime: endTime) || pref.isAllDay.booleanValue),
                  bridgeIds.contains(bridgeDetails.id),
                  pref.isActive.booleanValue/*,
                  pref.isBeta.booleanValue == (Utilities.environment == .testing || Utilities.environment == .development)*/
            else {
                print("\n\nDid not send to id: \(pref.deviceId.stringValue)\n\n")
                return
            }
            
            func sendNotification(status: String) {
                guard Utilities.environment != .development || pref.deviceId.stringValue == Secrets.devDeviceFCMId else {
                    return
                }
                print("\n\nSending to id: \(pref.deviceId.stringValue)\n\n")
                FcmManager.shared.send(
                    pref.deviceId.stringValue,
                    title: bridgeDetails.bridgeLocation,
                    body: "The \(bridge.name.capitalized) is now \(status)",
                    data: [
                        "badge": "0",
                        "sound": "default",
                        "priority": "high",
                        "interruption_level": "\(pref.notificationPriorityAsInt())",
                        "bridge_id": "\(bridgeDetails.id)",
                        "mutable_content" : "true"
                    ],
                    apns: FCMApnsApsObject(
                        badge: 0,
                        sound: "default",
                        priority: pref.notificationPriority.stringValue,
                        contentAvailable: false,
                        threadId: bridgeDetails.id,
                        mutableContent: true
                    ))
//                FcmManager.shared.send(
//                    pref.deviceId.stringValue,
//                    title: bridgeDetails.bridgeLocation,
//                    body: "The \(bridge.name.capitalized) is now \(status)",
//                    data: [
//                        "badge": "0",
//                        "sound": "default",
//                        "priority": "high",
//                        "interruption_level": "\(pref.notificationPriorityAsInt())",
//                        "bridge_id": "\(bridgeDetails.id)",
//                        "mutable-content" : "1"
//                    ]
//                )
            }
            switch bridge.status {
            case .up:
                sendNotification(status: BridgeStatus.up.rawValue)
            case .down:
                sendNotification(status: BridgeStatus.down.rawValue)
            case .maintenance:
                sendNotification(status: "under maintenance")
            case .unknown:
                sendNotification(status: "in an unknown state")
            }
        }
    }
    static func updateBridge(bridge: Bridge, db: Database) {
        getBridgeInDb(db: db) { bridges in
            let updateBridge = bridges.first { bridgeResponse in
                bridgeResponse.name == bridge.name
            }
            
            guard bridge.status.rawValue != updateBridge?.status else {
                return
            }
            let url = URL(string: "http://localhost:\(Secrets.runBindPort)/bridges")!

            var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer \(Secrets.internalEditBearerToken)"
            ]
            print("updateBridge = \(updateBridge)")
            let jsonDictionary: [String: Any] = [
                "id": updateBridge?.id ?? "",
                "name": bridge.name,
                "status": bridge.status.rawValue,
                "image_url" : "",
                "maps_url" : "",
                "address" : "",
                "latitude" : Double(0),
                "longitude" : Double(0),
                "bridge_location" : ""
            ]
            let data = try! JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
            let task = URLSession.shared.uploadTask(with: request, from: data) { (responseData, response, error) in
                if let error = error {
                    print("Error making PUT request: \(error.localizedDescription)")
                    return
                }
                
                if let responseCode = (response as? HTTPURLResponse)?.statusCode, let responseData = responseData {
                    guard responseCode == 200 else {
                        print("Invalid response code: \(responseCode)")
                        return
                    }
                    
                    if let responseJSONData = try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments) {
                        print("Response JSON data = \(responseJSONData)")
                    }
                }
            }
            task.resume()
            guard let updateBridge = updateBridge else {
                return
            }
//            if Utilities.environment != .development {
                postBridgeNotification(bridge: bridge, bridgeDetails: updateBridge)
//            }
        }
    }
    static func getBridgeInDb(db: Database, completion: @escaping ([BridgeResponse]) -> Void) {
        var request = URLRequest(url: URL(string: "http://localhost:\(Secrets.runBindPort)/bridges")!, timeoutInterval: Double.infinity)
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                return
            }
            
            if let response = response as? HTTPURLResponse {
                guard (200 ... 299) ~= response.statusCode else {
                    print("❌ Status code is \(response.statusCode)")
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                    let bridges = try jsonDecoder.decode([BridgeResponse].self, from: data)
                    completion(bridges)
                } catch {
                    print("json decoding error = \(error)")
                }
            }
        }
        task.resume()
    }
    static var bridgesUsed: [Bridge] = []
    static let maintenanceKeywords = ["maintenance", "until further notice", "issue"]
    
    static func addBridge(text: String, from user: User, name: String, db: Database) {
        if !bridgesUsed.contains(where: { bridge in
            bridge.name == name
        }) {
            if maintenanceKeywords.contains(text.lowercased()) {
                if text.lowercased().contains("finished") {
                    let bridge = Bridge(name: name, status: .down)
                    bridgesUsed.append(bridge)
                    BridgeFetch.updateBridge(bridge: bridge, db: db)
                } else {
                    let bridge = Bridge(name: name, status: .maintenance)
                    bridgesUsed.append(bridge)
                    BridgeFetch.updateBridge(bridge: bridge, db: db)
                }
            } else if text.lowercased().contains("closed") {
                let bridge = Bridge(name: name, status: .up)
                bridgesUsed.append(bridge)
                BridgeFetch.updateBridge(bridge: bridge, db: db)
            } else if text.lowercased().contains("open") {
                let bridge = Bridge(name: name, status: .down)
                bridgesUsed.append(bridge)
                BridgeFetch.updateBridge(bridge: bridge, db: db)
            } else {
                if user == .seattleDOTBridges {
                    let bridge = Bridge(name: name, status: .unknown)
                    bridgesUsed.append(bridge)
                    BridgeFetch.updateBridge(bridge: bridge, db: db)
                }
            }
        }
    }
    
    static func handleBridge(text: String, from user: User, db: Database) {
        print("Handling message: \(text)")
        switch text {
        case let str where str.contains("Ballard Bridge"):
            BridgeFetch.addBridge(text: text, from: user, name: "Ballard Bridge", db: db)
        case let str where str.contains("Fremont Bridge"):
            BridgeFetch.addBridge(text: text, from: user, name: "Fremont Bridge", db: db)
        case let str where str.contains("Montlake Bridge"):
            BridgeFetch.addBridge(text: text, from: user, name: "Montlake Bridge", db: db)
        case let str where str.contains("Lower Spokane St Bridge"):
            BridgeFetch.addBridge(text: text, from: user, name: "Spokane St Swing Bridge", db: db)
        case let str where str.contains("South Park Bridge"):
            BridgeFetch.addBridge(text: text, from: user, name: "South Park Bridge", db: db)
        case let str where str.contains("University Bridge"):
            BridgeFetch.addBridge(text: text, from: user, name: "University Bridge", db: db)
        case let str where str.contains("1st Ave S Bridge"):
            BridgeFetch.addBridge(text: text, from: user, name: "1st Ave S Bridge", db: db)
        default:
            break
        }
    }
    
    static func fetchTweets(db: Database) {
        BridgeFetch.bridgesUsed.removeAll()
        print("fetch tweets")
        TwitterFetch.shared.fetchTweet(username: .seattleDOTBridges) { response in
            for text in response {
                print("tweet.text = \(text)")
                BridgeFetch.handleBridge(text: text, from: .seattleDOTBridges, db: db)
            }
        }
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(1500)) {
            TwitterFetch.shared.fetchTweet(username: .SDOTTraffic) { response in
                for text in response {
                    print("tweet.text = \(text)")
                    BridgeFetch.handleBridge(text: text, from: .SDOTTraffic, db: db)
                }
            }
        }
    }
    
    static func streamTweets(db: Database) {
        print("start stream")
        TwitterFetch.shared.startStream { user, response in
            BridgeFetch.bridgesUsed.removeAll()
            for r in response {
                BridgeFetch.handleBridge(text: r, from: user, db: db)
            }
        }
    }
}
struct Bridge: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let status: BridgeStatus
}
enum BridgeStatus: String {
    case up
    case down
    case maintenance
    case unknown
}
struct BridgeResponse: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let status: String
    let imageUrl: String
    let mapsUrl: String
    let address: String
    let latitude: Double
    let longitude: Double
    let bridgeLocation: String
}

struct DirectoryResponse: Codable {
    let fields: Directory
}

struct Directory: Codable {
    let subscribedUsers: SubscribedUsers
    
//    init(subscribedUsers: SubscribedUsers) {
//        self.subscribedUsers = subscribedUsers.arrayValue.values.map({ $0.stringValue })
//    }
}

struct PrefResponse: Codable {
    let createTime: String
    let fields: Preferences
    let updateTime: String
    let name: String
}

struct Preferences: Codable {
    let bridgeIds: BridgeIds
    let days: Days
    let endTime: EndTime
    let id: Id
    let isActive: IsActive
    let isAllDay: IsAllDay
    let notificationPriority: NotificationPriority
    let startTime: StartTime
    let title: Title
    let deviceId: DeviceId
    let isBeta: isBeta
    
//    init(bridgeIds: BridgeIds, days: Days, endTime: EndTime, id: Id, isActive: IsActive, isAllDay: IsAllDay, notificationPriority: NotificationPriority, startTime: StartTime, title: Title, deviceToken: DeviceToken) {
//        self.bridgeIds = bridgeIds.arrayValue.values.map({ $0.stringValue })
//        self.days = days.arrayValue.values.map({ $0.stringValue })
//        self.endTime = endTime.stringValue
//        self.id = id.stringValue
//        self.isActive = isActive.booleanValue
//        self.isAllDay = isAllDay.booleanValue
//        self.notificationPriority = notificationPriority.stringValue
//        self.startTime = startTime.stringValue
//        self.title = title.stringValue
//        self.deviceToken = deviceToken.stringValue
//    }
    
    func notificationPriorityAsInt() -> Int {
        switch self.notificationPriority.stringValue {
        case "silent": return 0
        case "normal": return 1
        case "time sensitive": return 2
        default:
            return 1
        }
    }
}

struct SubscribedUsers: Codable {
    let arrayValue: ArrayValue
}

struct BridgeIds: Codable {
    let arrayValue: ArrayValue
}

struct ArrayValue: Codable {
    let values: [Value]
    
    func asStrings() -> [String] {
        self.values.map({ $0.stringValue })
    }
}

struct Value: Codable {
    let stringValue: String
}

struct Days: Codable {
    let arrayValue: ArrayValue
}

struct EndTime: Codable {
    let stringValue: String
}

struct Id: Codable {
    let stringValue: String
}

struct IsActive: Codable {
    let booleanValue: Bool
}

struct IsAllDay: Codable {
    let booleanValue: Bool
}

struct NotificationPriority: Codable {
    let stringValue: String
}

struct StartTime: Codable {
    let stringValue: String
}

struct Title: Codable {
    let stringValue: String
}

struct DeviceId: Codable {
    let stringValue: String
}

struct isBeta: Codable {
    let booleanValue: Bool
}

enum Day: String, CaseIterable, Codable, Hashable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
    
    static func currentDay() -> Self? {
        guard let day = Date().dayOfWeek() else {
            return nil
        }
        return Self(rawValue: day)
    }
    
    static func stringsCapitalized(for days: [Self]) -> [String] {
        days.map { $0.rawValue.capitalized }
    }
}

enum User: String {
    case seattleDOTBridges = "2768116808"
    case SDOTTraffic = "936366064518160384"
}

extension Formatter {
    static let today: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .init(identifier: "en_US_POSIX")
        dateFormatter.defaultDate = Calendar.current.startOfDay(for: Date())
        dateFormatter.dateFormat = "hh:mm a"
        return dateFormatter
    }()
}
extension Date {
    func dayOfWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).lowercased()
    }
}
struct AuthKey: Codable {
    let privateKey: String
}
