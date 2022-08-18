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

struct BridgeFetchEvery5SecJob: VaporCronSchedulable {
    typealias T = Void
    
    static var expression: String { "*/5 * * * * *" } // every 5 seconds

    static func task(on application: Application) -> EventLoopFuture<Void> {
        print("ComplexJob start")
        let bridgeIDs: [
            String : String] = ["Ballard Bridge" : "85c3d66a-b103-49ab-aa8b-26d153600d19",
            "1 Ave S Bridge" : "cc1a77e6-2b93-4781-849a-a9c794a2c1ec",
            "University Bridge" : "e4d0e7f3-db3e-42c7-9009-d42af978c4e3",
            "South Park Bridge" : "65c163b6-8b32-477a-b292-69ab0bcefc15",
            "Spokane St Swing Bridge" : "52ca4452-2bbd-4c48-b456-c6fcb33fc0b1",
            "Montlake Bridge" : "8e12ea9b-7f86-4940-becf-2ad8c09787f6",
            "Fremont Bridge" : "d6e22016-407f-494b-b11b-63458ad1210f"
        ]
        let bridgeFetch = TwitterFetch()
        var bridgesUsed: [Bridge] = []
        bridgeFetch.fetchTweet { response in
            switch response {
            case .success(let response):
                for tweet in response.data {
                    print("tweet.text = \(tweet.text)")
                    func addBridge(name: String) {
    //                    print("name = \(name)")
                        if !bridgesUsed.contains(where: { bridge in
                            bridge.name == name
                        }) {
                            func updateBridge(bridge: Bridge) {
                                let url = URL(string: "http://localhost:8080/bridges")!

                                var request = URLRequest(url: url)
                                request.httpMethod = "PUT"
                                request.allHTTPHeaderFields = [
                                    "Content-Type": "application/json",
                                    "Accept": "application/json"
                                ]
                                let jsonDictionary: [String: String] = [
                                    "id": bridgeIDs[bridge.name] ?? "",
                                    "name": bridge.name,
                                    "status": bridge.status.rawValue
                                ]
                                
                                let data = try! JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
                                URLSession.shared.uploadTask(with: request, from: data) { (responseData, response, error) in
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
                                }.resume()
                            }
                            if tweet.text.lowercased().contains("opened to traffic") {
                                let bridge = Bridge(name: name, status: .down)
                                bridgesUsed.append(bridge)
                                updateBridge(bridge: bridge)
                            } else if tweet.text.lowercased().contains("maintenance") {
                                if tweet.text.lowercased().contains("finished") {
                                    let bridge = Bridge(name: name, status: .down)
                                    bridgesUsed.append(bridge)
                                    updateBridge(bridge: bridge)
                                } else {
                                    let bridge = Bridge(name: name, status: .maintenance)
                                    bridgesUsed.append(bridge)
                                    updateBridge(bridge: bridge)
                                }
                            } else {
                                let bridge = Bridge(name: name, status: .up)
                                bridgesUsed.append(bridge)
                                updateBridge(bridge: bridge)
                            }
                        }
                    }
                    switch tweet.text {
                    case let str where str.contains("Ballard Bridge"):
                        addBridge(name: "Ballard Bridge")
                    case let str where str.contains("Fremont Bridge"):
                        addBridge(name: "Fremont Bridge")
                    case let str where str.contains("Montlake Bridge"):
                        addBridge(name: "Montlake Bridge")
                    case let str where str.contains("Spokane St Swing Bridge"):
                        addBridge(name: "Spokane St Swing Bridge")
                    case let str where str.contains("South Park Bridge"):
                        addBridge(name: "South Park Bridge")
                    case let str where str.contains("University Bridge"):
                        addBridge(name: "University Bridge")
                    case let str where str.contains("1 Ave S Bridge"):
                        addBridge(name: "1 Ave S Bridge")
                    default:
                        break
                    }
                }
            case .failure(let error):
                print("error = \(error)")
            }
        }
        return application.eventLoopGroup.future().always { _ in
            print("ComplexJob fired")
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
