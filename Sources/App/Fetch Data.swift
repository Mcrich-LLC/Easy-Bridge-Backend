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

enum HttpError: Error {
    case badResponse
    case badURL
}

class TwitterFetch {
    
    static var shared = TwitterFetch()
    
    private var isStreaming = false
    private let streamPollingRate = 500
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
    func stopStream() {
        self.isStreaming = false
    }
    
    func fetchTweet(username: User, completion: @escaping (Result<Feed, ParserError>) -> Void) {
        guard let feedUrl = URL(string: "https://nitter.net/\(username.rawValue.lowercased())/rss") else { return }
        let parser = FeedParser(URL: feedUrl)
        let parsedResult = parser.parse()
        completion(parsedResult)
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
