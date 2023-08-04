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
    private let streamPollingRate = 500
    func feedUrl(username: String, format: FeedTypes) -> URL? {
        if Utilities.environment == .development {
            return URL(string: "http://localhost:\(Secrets.rssBridgePort)/?action=display&bridge=TwitterBridge&context=By+username&u=\(username.lowercased())&norep=on&nopinned=on&nopic=on&noimg=on&format=\(format.rawValue.capitalized)")
        } else {
            return URL(string: "http://rss-bridge:\(Secrets.rssBridgePort)/?action=display&bridge=TwitterBridge&context=By+username&u=\(username.lowercased())&norep=on&nopinned=on&nopic=on&noimg=on&format=\(format.rawValue.capitalized)")
        }
    }
    
    func stopStream() {
        self.isStreaming = false
    }
    
    // FeedKit
    func startStream(completion: @escaping (User, Result<Feed, ParserError>) -> Void) {
        self.isStreaming = true
        func repeatBridges() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(streamPollingRate)) {
                if self.isStreaming {
                    self.fetchTweet(username: .seattleDOTBridges) { result in
                        completion(.seattleDOTBridges, result)
                    }
                    repeatBridges()
                } else {
                    return
                }
            }
        }
        func repeatTraffic() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(streamPollingRate)) {
                if self.isStreaming {
                    self.fetchTweet(username: .SDOTTraffic) { result in
                        completion(.SDOTTraffic, result)
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
    
    func fetchTweet(username: User, completion: @escaping (Result<Feed, ParserError>) -> Void) {
        guard let feedUrl = self.feedUrl(username: username.rawValue, format: .atom) else { return }
        print("FeedUrl: \(feedUrl.absoluteString)")
        let parser = FeedParser(URL: feedUrl)
        let parsedResult = parser.parse()
        completion(parsedResult)
    }
    
    // JSON Fetch
    
    func startStream(completion: @escaping (User, RawFeed) -> Void) {
        self.isStreaming = true
        func repeatBridges() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(streamPollingRate)) {
                if self.isStreaming {
                    self.fetchTweet(username: .seattleDOTBridges) { result in
                        completion(.seattleDOTBridges, result)
                    }
                    repeatBridges()
                } else {
                    return
                }
            }
        }
        func repeatTraffic() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(streamPollingRate)) {
                if self.isStreaming {
                    self.fetchTweet(username: .SDOTTraffic) { result in
                        completion(.SDOTTraffic, result)
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
    
    func fetchTweet(username: User, completion: @escaping (RawFeed) -> Void) {
        guard let feedUrl = self.feedUrl(username: username.rawValue, format: .json) else { return }
        print("FeedUrl: \(feedUrl.absoluteString)")

        // Create a URL session
        let session = URLSession.shared

        // Create a data task to perform the GET request
        let task = session.dataTask(with: feedUrl) { data, response, error in
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
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let feed = try decoder.decode(RawFeed.self, from: data)
                        completion(feed)
                    } catch {
                        print("error parsing tweet: \(error)")
                    }
                } else {
                    print("No data received.")
                }
            } else {
                // Unsuccessful request
                print("Request failed with status code: \(httpResponse.statusCode)")
            }
        }

        // Start the data task
        task.resume()
    }
    
    // nitter.net Fetch
    
    func startStream(completion: @escaping (User, String) -> Void) {
        self.isStreaming = true
        func repeatBridges() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(streamPollingRate)) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(streamPollingRate)) {
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
        let url = URL(string: "http://nitter:8080/\(username.rawValue)")!
        
        // Create a URL session
        let session = URLSession.shared

        // Create a data task to perform the GET request
        let task = session.dataTask(with: url) { data, response, error in
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
