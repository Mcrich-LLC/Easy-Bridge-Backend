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
    func startStream(completion: @escaping (User, Result<Feed, ParserError>) -> Void) {
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
        
//        client.v2.stream.searchStream(searchStreamRequest).streamResponse(queue: .global(qos: .default)) { response in
//            if (200 ... 299) ~= response.response?.statusCode ?? 0 {
//                do {
//                    let jsonDecoder = JSONDecoder()
//                    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
//                    let result = try jsonDecoder.decode(StreamResponse.self, from: (response.data ?? response.prettyString.toJSON())!)
//                    print("streamed \(result)")
//                    completion(.success(result))
//                } catch {
//                    print("error, unable to decode stream")
//                }
//            } else {
//                completion(.failure(HttpError.badResponse))
//                print("❌ Status code is \(String(describing: response.response?.statusCode))")
//            }
//        }
    }
    func stopStream() {
        self.isStreaming = false
    }
    
    func fetchTweet(username: User, completion: @escaping (Result<Feed, ParserError>) -> Void) {
        guard let feedUrl = URL(string: "https://rss-bridge.org/bridge01/?action=display&bridge=TwitterBridge&context=By+username&u=\(username)&norep=on&noretweet=on&nopinned=on&nopic=on&noimg=on&noimgscaling=on&format=Mrss") else { return }
        let parser = FeedParser(URL: feedUrl)
        let parsedResult = parser.parse()
        completion(parsedResult)
//        do {
//            print("started twitter fetch")
//            var request = URLRequest(url: URL(string: "https://api.twitter.com/2/users/\(id)/tweets")!,
//                                     timeoutInterval: Double.infinity)
//            
//            request.addValue("Bearer \(Secrets.twitterBearerToken)", forHTTPHeaderField: "Authorization")
//            
//            request.httpMethod = "GET"
//            
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                guard error == nil else {
//                    completion(.failure(error!))
//                    return
//                }
//                
//                if let response = response as? HTTPURLResponse {
//                    guard (200 ... 299) ~= response.statusCode else {
//                        completion(.failure(HttpError.badResponse))
//                        print("❌ Status code is \(response.statusCode)")
//                        return
//                    }
//                    
//                    guard let data = data else {
//                        completion(.failure(error!))
//                        return
//                    }
//                    
//                    do {
//                        let jsonDecoder = JSONDecoder()
//                        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
//                        let result = try jsonDecoder.decode(Response.self, from: data)
//                        print("result = \(result)")
//                        completion(.success(result))
//                    } catch {
//                        completion(.failure(error))
//                    }
//                }
//            }
//            task.resume()
//        }
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
