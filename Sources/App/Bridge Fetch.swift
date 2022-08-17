//
//  Bridge Fetch.swift
//  
//
//  Created by Morris Richman on 8/17/22.
//

import Foundation
import Vapor
import VaporCron

struct BridgeFetchEvery5MinJob: VaporCronSchedulable {
    typealias T = Void
    
    static var expression: String { "*/5 * * * *" } // every 5 minutes

    static func task(on application: Application) -> EventLoopFuture<Void> {
        print("ComplexJob start")
        let bridgeIDs: [String : String] = [:]
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
                                print("update \(bridge.name)")
                                // declare the parameter as a dictionary that contains string as key and value combination. considering inputs are valid
                                  
                                let parameters: [String: Any] = ["name": bridge.name, "status": bridge.status.rawValue]
                                  
                                  // create the url with URL
                                  let url = URL(string: "localhost:8080/bridges")! // change server url accordingly
                                  
                                  // create the session object
                                  let session = URLSession.shared
                                  
                                  // now create the URLRequest object using the url object
                                  var request = URLRequest(url: url)
                                  request.httpMethod = "POST" //set http method as POST
                                  
                                  // add headers for the request
                                  request.addValue("application/json", forHTTPHeaderField: "Content-Type") // change as per server requirements
                                  request.addValue("application/json", forHTTPHeaderField: "Accept")
                                  
                                  do {
                                    // convert parameters to Data and assign dictionary to httpBody of request
                                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                                  } catch let error {
                                    print(error.localizedDescription)
                                    return
                                  }
                                  
                                  // create dataTask using the session object to send data to the server
                                  let task = session.dataTask(with: request) { data, response, error in
                                    
                                    if let error = error {
                                      print("Post Request Error: \(error.localizedDescription)")
                                      return
                                    }
                                    
                                    // ensure there is valid response code returned from this HTTP response
                                    guard let httpResponse = response as? HTTPURLResponse,
                                          (200...299).contains(httpResponse.statusCode)
                                    else {
                                      print("Invalid Response received from the server")
                                      return
                                    }
                                    
                                    // ensure there is data returned
                                    guard let responseData = data else {
                                      print("nil Data received from the server")
                                      return
                                    }
                                    
                                    do {
                                      // create json object from data or use JSONDecoder to convert to Model stuct
                                      if let jsonResponse = try JSONSerialization.jsonObject(with: responseData, options: .mutableContainers) as? [String: Any] {
                                        print(jsonResponse)
                                        // handle json response
                                      } else {
                                        print("data maybe corrupted or in wrong format")
                                        throw URLError(.badServerResponse)
                                      }
                                    } catch let error {
                                      print(error.localizedDescription)
                                    }
                                  }
                                  // perform the task
//                                  task.resume()
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

//class BridgeFetch {
//    var bridgesUsed: [Bridge] = []
//    var tweets: [Tweet] = [] {
//        didSet {
//            for tweet in tweets {
//                print("tweet.text = \(tweet.text)")
//                func addBridge(name: String) {
////                    print("name = \(name)")
//                    if !bridgesUsed.contains(where: { bridge in
//                        bridge.name == name
//                    }) {
//                        if tweet.text.lowercased().contains("opened to traffic") {
//                            let bridge = Bridge(name: name, status: .down)
//                            bridgesUsed.append(bridge)
//                            updateBridge(bridge: bridge)
//                        } else if tweet.text.lowercased().contains("maintenance") {
//                            if tweet.text.lowercased().contains("finished") {
//                                let bridge = Bridge(name: name, status: .down)
//                                bridgesUsed.append(bridge)
//                                updateBridge(bridge: bridge)
//                            } else {
//                                let bridge = Bridge(name: name, status: .maintenance)
//                                bridgesUsed.append(bridge)
//                                updateBridge(bridge: bridge)
//                            }
//                        } else {
//                            let bridge = Bridge(name: name, status: .up)
//                            bridgesUsed.append(bridge)
//                            updateBridge(bridge: bridge)
//                        }
//                    }
//                }
//                switch tweet.text {
//                case let str where str.contains("Ballard Bridge"):
//                    addBridge(name: "Ballard Bridge")
//                case let str where str.contains("Fremont Bridge"):
//                    addBridge(name: "Fremont Bridge")
//                case let str where str.contains("Montlake Bridge"):
//                    addBridge(name: "Montlake Bridge")
//                case let str where str.contains("Spokane St Swing Bridge"):
//                    addBridge(name: "Spokane St Swing Bridge")
//                case let str where str.contains("South Park Bridge"):
//                    addBridge(name: "South Park Bridge")
//                case let str where str.contains("University Bridge"):
//                    addBridge(name: "University Bridge")
//                case let str where str.contains("1 Ave S Bridge"):
//                    addBridge(name: "1 Ave S Bridge")
//                default:
//                    break
//                }
//            }
//        }
//    }
//    func fetchData() {
//        let dataFetch = TwitterFetch()
//        print("Start data fetch")
//        DispatchQueue.main.async {
//            dataFetch.fetchTweet { response in
//                switch response {
//                case .success(let response):
//                    DispatchQueue.main.async {
//                        self.tweets = response.data
//                    }
//                case .failure(let error):
//                    print("error = \(error)")
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
//                    self.fetchData()
//                }
//            }
//        }
//    }
//
//}
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
