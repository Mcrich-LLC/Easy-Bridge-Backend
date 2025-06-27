//
//  Fetch Data from Twitter.swift
//  Seattle Bridge Tracker
//
//  Created by Morris Richman on 8/16/22.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import FeedKit
import SwiftSoup

enum HttpError: Error {
    case badResponse
    case badURL
}

class TwitterFetch {
    
    static var shared = TwitterFetch()
    
    enum FeedTypes: String {
        case atom
        case rss
        case json
    }
    
    private var isStreaming = false
    private let streamPollingRate = 2000
    
    func nitterUrl(username: String) -> URL {
//        if Utilities.environment == .development {
            return URL(string: "https://nitter.space/\(username.lowercased())")!
//        } else {
//            return URL(string: "http://nitter:8080/\(username.lowercased())")!
//        }
    }
    
    func stopStream() {
        self.isStreaming = false
    }
    
    // nitter.net Fetch
    
    func startStream(completion: @escaping (User, String) -> Void) {
        self.isStreaming = true
        func repeatBridges() {
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(streamPollingRate)) {
                if self.isStreaming {
                    self.fetchTweet(username: .seattleDOTBridges) { result in
                        completion(.seattleDOTBridges, result.first ?? "")
                    }
                    repeatBridges()
                } else {
                    return
                }
            }
        }
        func repeatTraffic() {
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(streamPollingRate)) {
                if self.isStreaming {
                    self.fetchTweet(username: .SDOTTraffic) { result in
                        completion(.SDOTTraffic, result.first ?? "")
                    }
                    repeatBridges()
                } else {
                    return
                }
            }
        }
        repeatBridges()
        repeatTraffic()
    }
    
    func fetchTweet(username: User, completion: @escaping ([String]) -> Void) {
        
        // Create a URL session
        let session = URLSession.shared
        let url = nitterUrl(username: username.rawValue)
        var request = URLRequest(url: url)
        
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
         request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
         request.addValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
         request.addValue("u=0, i", forHTTPHeaderField: "Priority")
         request.addValue("https://twiiit.com/", forHTTPHeaderField: "Referer")
         request.addValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
         request.addValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
         request.addValue("none", forHTTPHeaderField: "Sec-Fetch-Site")
         request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
         request.addValue("cf_clearance=O.edHMSzb8MD2dukVZYT18t.WmCpSQ3QSU.OvscaF2g-1750995812-1.2.1.1-rcfKguJznUvC0d7SuXeEevMJSZ.Mjp11wFIfiswh8D5o9O9ZXoUxpcKCWPXhT6lbDvc3vj.vdTglSDq.8ygjCGUFUN1qhzJxFZ6uSG4RHxhGB1WujDtI09qQE1kzCvr8WTM7385vDxkjIlqgiPVGJ81p2eVOdh_Hi9B3TF8hVGnAEqemJzI9oPz9U2rvWOhykwCiHxiEKy9T8loWuYP4jau8lhXGw8p8PU7I0EkvqC09q_sVOTb2v27iBOoPITlEQPjy7X23n6GDPLUQSm4FoGxiFN.nBCb2tpRhtTj1Wl2kb.dFxw2El2HMqmv2ga5e.rz1Dmc0Aw.W.jdRzk3uru8qPT8rbzElyM7hzRLT9SzaySAzNveTkVy395_VEAnC", forHTTPHeaderField: "Cookie")

        // Create a data task to perform the GET request
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            // Check if a response was received
            guard let httpResponse = response as? HTTPURLResponse else {
                print("No response received.")
                return
            }

            // Check the status code of the response
            if httpResponse.statusCode == 200 {
                // Successful request
                if let data = data {
                    // Parse and process the response data
                    do {
                        guard let html = String(data: data, encoding: .utf8) else { return }
                        let doc: Document = try SwiftSoup.parse(html)
                        let divs: Elements = try doc.select("div")
                        for div in divs {
                            let divClass: String = try div.attr("class")
                            if divClass.lowercased().contains("timeline-container") {
                                guard let timeline = try div.select("div").first()?.select("div") else { return }
                                var count = 0
                                var array: [String] = [] {
                                    didSet {
                                        if array.count == count {
                                            completion(array)
                                        }
                                    }
                                }
                                for timelineItem in timeline {
                                    let timelineItemClass: String = try timelineItem.attr("class")
                                    if timelineItemClass.lowercased().contains("timeline-item") {
                                        guard let body = try div.select("div").first()?.select("div") else { return }
                                        count = body.count
                                        for bodyItem in body {
                                            let bodyItemClass: String = try bodyItem.attr("class")
                                            if bodyItemClass.lowercased().contains("tweet-content media-body") {
                                                let text = try bodyItem.text()
                                                array.append(text)
//                                                completion(["The Fremont Bridge has closed to traffic at 4:59:55 PM"])
//                                                completion(["The Fremont Bridge has reopened to traffic at 4:59:55 PM"])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        print("error parsing tweet: \(error)")
                    }
                } else {
                    print("No data received.")
                }
            } else {
                // Unsuccessful request
                print("Nitter url: \(url)")
                print("Request failed with status code: \(httpResponse.statusCode)")
            }
        }

        // Start the data task
        task.resume()
    }
}

extension String {
    func toJSON() -> Data? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        return try? jsonEncoder.encode(data)
    }
}

struct Item: Codable {
    let id: URL
    let title: String
    let author: Author
}

struct Author: Codable {
    let name: String
}

struct RawFeed: Codable {
    let title: String
    let items: [Item]
}
