//
//  Fetch Data from Twitter.swift
//  Seattle Bridge Tracker
//
//  Created by Morris Richman on 8/16/22.
//

import Foundation
import TwitterAPIKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum HttpError: Error {
    case badResponse
    case badURL
}

class TwitterFetch {
    
    static var shared = TwitterFetch()
    
    let client = TwitterAPIClient(.bearer(Secrets.twitterBearerToken))
    let searchStreamRequest = GetTweetsSearchStreamRequestV2()
    func startStream(completion: @escaping (Result<StreamResponse, Error>) -> Void) {
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
        client.v2.stream.searchStream(searchStreamRequest).cancel()
    }
    
    func fetchTweet(id: String, completion: @escaping (Result<Response, Error>) -> Void) {
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
