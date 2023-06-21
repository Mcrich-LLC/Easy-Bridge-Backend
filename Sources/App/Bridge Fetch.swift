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
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/easy-bridge-tracker/databases/(default)/documents/Directory/\(bridge.id)?key=\(Secrets.firebaseWebAuthToken)") else { return }
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
                    print("result = \(directory)")
                    for path in directory.fields.subscribedUsers {
                        getPushNotificationPreferences(path: path, completion: completion)
                    }
                } catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    private static func currentTimeIsBetween(startTime: String, endTime: String) -> Bool {
        guard let start = Formatter.today.date(from: startTime),
              let end = Formatter.today.date(from: endTime) else {
            return false
        }
        return DateInterval(start: start, end: end).contains(Date())
    }
    
    static func postBridgeNotification(bridge: Bridge, bridgeDetails: BridgeResponse) {
        getPushNotificationList(bridge: bridgeDetails) { pref in
            let bridgeId = pref.bridgeIds
            guard let day = Day.currentDay(),
                  (pref.days).contains(day.rawValue) && (currentTimeIsBetween(startTime: pref.startTime, endTime: pref.endTime) || pref.isAllDay) && pref.bridgeIds.contains(bridgeDetails.id) && pref.isActive
            else {
                return
            }
            let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "Post"
            request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(Secrets.firebaseCloudMessagingBearerToken)"
            ]
            let bridgeName = "\(bridgeDetails.bridgeLocation)_\(bridge.name)".replacingOccurrences(of: " Bridge", with: "").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "st", with: "").replacingOccurrences(of: "nd", with: "").replacingOccurrences(of: "3rd", with: "").replacingOccurrences(of: "th", with: "").replacingOccurrences(of: " ", with: "_")
            func sendNotification(status: String) {
                print("send status notification")
                let message = """
            {
              "to": "\(pref.deviceToken)",
              "priority": "high",
              "mutable_content": true,
              "notification": {
                "title": "\(bridgeDetails.bridgeLocation)",
                "body": "The \(bridge.name.capitalized) is now \(status)",
                "badge": 0,
                "sound": "default",
                "content_availible": true
              },
              "data": {
                  "interruption_level": \(pref.notificationPriorityAsInt()),
                  "bridge_id": "\(bridgeDetails.id)"
              }
            }
            """
                let data = message.data(using: .utf8)
                let task = URLSession.shared.uploadTask(with: request, from: data) { (responseData, response, error) in
                    if let error = error {
                        print("Error making Post request: \(error.localizedDescription)")
                        return
                    }
                    
                    if let responseCode = (response as? HTTPURLResponse)?.statusCode, let responseData = responseData {
                        guard responseCode == 200 else {
                            print("Invalid Firebase response code: \(responseCode)")
                            return
                        }
                        
                        if let responseJSONData = try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments) {
                            print("Firebase Response JSON data = \(responseJSONData)")
                        }
                    }
                }
                task.resume()
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
            let url = URL(string: "http://localhost:\(Secrets.runBindPort)/bridges")!

            var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer \(Secrets.internalEditBearerToken)"
            ]
            let updateBridge = bridges.first { bridgeResponse in
                bridgeResponse.name == bridge.name
            }
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
            print("jsonDict = \(jsonDictionary)")
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
            if Utilities.environment == .production {
                postBridgeNotification(bridge: bridge, bridgeDetails: updateBridge)
            }
        }
    }
    static func getBridgeInDb(db: Database, completion: @escaping ([BridgeResponse]) -> Void) {
        var request = URLRequest(url: URL(string: "http://localhost:\(Secrets.runBindPort)/bridges")!,
                                 timeoutInterval: Double.infinity)
        
        request.addValue("Bearer \(Secrets.twitterBearerToken)", forHTTPHeaderField: "Authorization")
        
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
                    print("result = \(bridges)")
                    completion(bridges)
                } catch {
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
            switch response {
            case .success(let feed):
                guard let rssFeed = feed.rssFeed?.items else { return }
                for item in rssFeed {
                    if let text = item.title {
                        print("tweet.text = \(text)")
                        BridgeFetch.handleBridge(text: text, from: .seattleDOTBridges, db: db)
                    }
                }
            case .failure(let error):
                print("error = \(error)")
            }
        }
        TwitterFetch.shared.fetchTweet(username: .SDOTTraffic) { response in
            switch response {
            case .success(let feed):
                guard let rssFeed = feed.rssFeed?.items else { return }
                for item in rssFeed {
                    if let text = item.title {
                        print("tweet.text = \(text)")
                        BridgeFetch.handleBridge(text: text, from: .SDOTTraffic, db: db)
                    }
                }
            case .failure(let error):
                print("error = \(error)")
            }
        }
    }
    
    static func streamTweets(db: Database) {
        print("start stream")
        TwitterFetch.shared.startStream { user, response in
            switch response {
            case .success(let feed):
                guard let rssFeed = feed.rssFeed?.items, let item = rssFeed.first, let text = item.title else { return }
                BridgeFetch.bridgesUsed.removeAll()
                BridgeFetch.handleBridge(text: text, from: user, db: db)
            case .failure(let error):
                print("error = \(error)")
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
    let subscribedUsers: [String]
    
    init(subscribedUsers: SubscribedUsers) {
        self.subscribedUsers = subscribedUsers.arrayValue.values.map({ $0.stringValue })
    }
}

struct PrefResponse: Codable {
    let createTime: String
    let fields: Preferences
    let updateTime: String
    let name: String
}

struct Preferences: Codable {
    let bridgeIds: [String]
    let days: [String]
    let endTime: String
    let id: String
    let isActive: Bool
    let isAllDay: Bool
    let notificationPriority: String
    let startTime: String
    let title: String
    let deviceToken: String
    
    init(bridgeIds: BridgeIds, days: Days, endTime: EndTime, id: Id, isActive: IsActive, isAllDay: IsAllDay, notificationPriority: NotificationPriority, startTime: StartTime, title: Title, deviceToken: DeviceToken) {
        self.bridgeIds = bridgeIds.arrayValue.values.map({ $0.stringValue })
        self.days = days.arrayValue.values.map({ $0.stringValue })
        self.endTime = endTime.stringValue
        self.id = id.stringValue
        self.isActive = isActive.booleanValue
        self.isAllDay = isAllDay.booleanValue
        self.notificationPriority = notificationPriority.stringValue
        self.startTime = startTime.stringValue
        self.title = title.stringValue
        self.deviceToken = deviceToken.stringValue
    }
    
    func notificationPriorityAsInt() -> Int {
        switch self.notificationPriority {
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

struct DeviceToken: Codable {
    let stringValue: String
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
    case seattleDOTBridges = "SDOTBridges"
    case SDOTTraffic = "SDOTTraffic"
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
