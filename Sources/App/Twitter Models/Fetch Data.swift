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

class TwitterFetch : NSObject, URLSessionDataDelegate {
    
    static var shared = TwitterFetch()
    
    private var session: URLSession! = nil
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    private var streamingTask: URLSessionDataTask? = nil
    
    var isStreaming: Bool { return self.streamingTask != nil }
    
    func startStreaming() {
        print("start stream")
        precondition( !self.isStreaming )
        
        let url = URL(string: "https://api.twitter.com/2/tweets/search/stream?tweet.fields=id,text")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(Secrets.twitterBearerToken)", forHTTPHeaderField: "Authorization")
        let task = self.session.uploadTask(withStreamedRequest: request)
        self.streamingTask = task
        task.resume()
    }
    
    func stopStreaming() {
        guard let task = self.streamingTask else {
            return
        }
        self.streamingTask = nil
        task.cancel()
        self.closeStream()
    }
    
    var outputStream: OutputStream? = nil
    
    private func closeStream() {
        if let stream = self.outputStream {
            stream.close()
            self.outputStream = nil
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        self.closeStream()
        
        var inStream: InputStream? = nil
        var outStream: OutputStream? = nil
        Stream.getBoundStreams(withBufferSize: 4096, inputStream: &inStream, outputStream: &outStream)
        self.outputStream = outStream
        
        completionHandler(inStream)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        NSLog("task data: %@", data as NSData)
        
        do {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try jsonDecoder.decode([Tweet].self, from: data)
            print("result = \(result)")
            for tweet in result {
                BridgeFetch.handleBridge(text: tweet.text)
            }
        } catch {
            print("error, could not decode")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError? {
            NSLog("task error: %@ / %d", error.domain, error.code)
        } else {
            NSLog("task complete")
        }
    }
    func fetchTweet(id: String, completion: @escaping (Result<Response, Error>) -> Void) {
            do {
                print("started twitter fetch")
                var request = URLRequest(url: URL(string: "https://api.twitter.com/2/users/\(id)/tweets")!,
                                         timeoutInterval: Double.infinity)
                
                request.addValue("Bearer \(Secrets.twitterBearerToken)", forHTTPHeaderField: "Authorization")
                
                request.httpMethod = "GET"
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard error == nil else {
                        completion(.failure(error!))
                        return
                    }
                    
                    if let response = response as? HTTPURLResponse {
                        guard (200 ... 299) ~= response.statusCode else {
                            completion(.failure(HttpError.badResponse))
                            print("❌ Status code is \(response.statusCode)")
                            return
                        }
                        
                        guard let data = data else {
                            completion(.failure(error!))
                            return
                        }
                        
                        do {
                            let jsonDecoder = JSONDecoder()
                            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                            let result = try jsonDecoder.decode(Response.self, from: data)
                            print("result = \(result)")
                            completion(.success(result))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
                task.resume()
            }
        }
}
