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

enum HttpError: Error {
    case badResponse
    case badURL
}

class TwitterFetch {
    
    static var shared = TwitterFetch()
    
    private var isStreaming = false
    func startStream(completion: @escaping (User, Result<[RssItem], Error>) -> Void) {
        self.isStreaming = true
        func repeatBridges() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(50)) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(50)) {
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
    
    func fetchTweet(username: User, completion: @escaping (Result<[RssItem], Error>) -> Void) {
        guard let feedUrl = URL(string: "https://rss-bridge.org/bridge01/?action=display&bridge=TwitterBridge&context=By+username&u=\(username.rawValue)&norep=on&noretweet=on&nopinned=on&nopic=on&noimg=on&noimgscaling=on&format=Json") else { return }
        
        URLSession.shared.dataTask(with: feedUrl) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: nil))) // Handle invalid data case
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let rssModel = try decoder.decode(RssModel.self, from: data)
                completion(.success(rssModel.items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
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
