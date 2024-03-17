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
    
    enum FeedTypes: String {
        case atom
        case rss
        case json
    }
    
    private var isStreaming = false
    private let streamPollingRate = 10000
    
    func scraperUrl(username: String) -> URL {
        if Utilities.environment == .development {
            return URL(string: "http://127.0.0.1:5000/tweets/\(username.lowercased())")!
        } else {
            return URL(string: "http://twitter_scraper:5000/tweets\(username.lowercased())")!
        }
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
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(Int(Double(streamPollingRate)*1.5.rounded()))) {
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
        let url = scraperUrl(username: username.rawValue)
        let request = URLRequest(url: url)

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
                        let jsonDecoder = JSONDecoder()
                        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                        
                        let tweets = try jsonDecoder.decode([String].self, from: data)
                        completion(tweets)
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
