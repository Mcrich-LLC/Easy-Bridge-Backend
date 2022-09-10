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

//struct BridgeFetchEvery5SecJob: VaporCronSchedulable {
//    typealias T = Void
//    
//    static var expression: String { "*/5 * * * * *" } // every 5 seconds
//
//    static func task(on application: Application) -> EventLoopFuture<Void> {
//        print("ComplexJob start")
//        BridgeFetch.fetchTweets()
//        return application.eventLoopGroup.future().always { _ in
//            print("ComplexJob fired")
//        }
//    }
//}
struct BridgeFetch {
        static func updateBridge(bridge: Bridge) {
            let seattleBridgeIDs: [
                String : String] = ["Ballard Bridge" : "85c3d66a-b103-49ab-aa8b-26d153600d19",
                "1 Ave S Bridge" : "cc1a77e6-2b93-4781-849a-a9c794a2c1ec",
                "University Bridge" : "e4d0e7f3-db3e-42c7-9009-d42af978c4e3",
                "South Park Bridge" : "65c163b6-8b32-477a-b292-69ab0bcefc15",
                "Spokane St Swing Bridge" : "52ca4452-2bbd-4c48-b456-c6fcb33fc0b1",
                "Montlake Bridge" : "8e12ea9b-7f86-4940-becf-2ad8c09787f6",
                "Fremont Bridge" : "d6e22016-407f-494b-b11b-63458ad1210f"
            ]
            let url = URL(string: "http://localhost:8080/bridges")!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer \(Secrets.editBearerToken)"
            ]
            let jsonDictionary: [String: Any] = [
                "id": seattleBridgeIDs[bridge.name] ?? "",
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
        }
    
    static func addBridge(text: String, name: String) {
        var seattleBidgesUsed: [Bridge] = []
        if !seattleBidgesUsed.contains(where: { bridge in
            bridge.name == name
        }) {
            if text.lowercased().contains("opened to traffic") {
                let bridge = Bridge(name: name, status: .down)
                seattleBidgesUsed.append(bridge)
                BridgeFetch.updateBridge(bridge: bridge)
            } else if text.lowercased().contains("maintenance") {
                if text.lowercased().contains("finished") {
                    let bridge = Bridge(name: name, status: .down)
                    seattleBidgesUsed.append(bridge)
                    BridgeFetch.updateBridge(bridge: bridge)
                } else {
                    let bridge = Bridge(name: name, status: .maintenance)
                    seattleBidgesUsed.append(bridge)
                    BridgeFetch.updateBridge(bridge: bridge)
                }
            } else {
                let bridge = Bridge(name: name, status: .up)
                seattleBidgesUsed.append(bridge)
                BridgeFetch.updateBridge(bridge: bridge)
            }
        }
    }
    
    static func handleBridge(text: String) {
        switch text {
        case let str where str.contains("Ballard Bridge"):
            BridgeFetch.addBridge(text: text, name: "Ballard Bridge")
        case let str where str.contains("Fremont Bridge"):
            BridgeFetch.addBridge(text: text, name: "Fremont Bridge")
        case let str where str.contains("Montlake Bridge"):
            BridgeFetch.addBridge(text: text, name: "Montlake Bridge")
        case let str where str.contains("Spokane St Swing Bridge"):
            BridgeFetch.addBridge(text: text, name: "Spokane St Swing Bridge")
        case let str where str.contains("South Park Bridge"):
            BridgeFetch.addBridge(text: text, name: "South Park Bridge")
        case let str where str.contains("University Bridge"):
            BridgeFetch.addBridge(text: text, name: "University Bridge")
        case let str where str.contains("1st Ave S Bridge"):
            BridgeFetch.addBridge(text: text, name: "1 Ave S Bridge")
        default:
            break
        }
    }
    
    static func fetchTweets() {
        print("fetch tweets")
        TwitterFetch.shared.fetchTweet(id: "2768116808") { response in
            switch response {
            case .success(let response):
                for tweet in response.data {
                    print("tweet.text = \(tweet.text)")
                    BridgeFetch.handleBridge(text: tweet.text)
                }
            case .failure(let error):
                print("error = \(error)")
            }
        }
    }
    
    static func streamTweets() {
        TwitterFetch.shared.startStream { response in
            switch response {
            case .success(let response):
                BridgeFetch.handleBridge(text: response.data.text)
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
}
