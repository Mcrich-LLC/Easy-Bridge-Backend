//
//  File.swift
//  
//
//  Created by Morris Richman on 3/22/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class SystemNotifications {
    static func pushStartup() {
        push(title: "Easy Bridge Backend", body: "Easy Bridge Backend Started Up")
    }
    static func pushShutdown() {
        push(title: "Easy Bridge Backend", body: "Easy Bridge Backend Shutdown")
    }
    static func pushCrash(error: String) {
        push(title: "Easy Bridge Backend", body: "Easy Bridge Backend Crashed with error: \(error)")
    }
    private static func push(title: String, body: String) {
        guard Secrets.pushoverNotificationKey != "get-from-pushover.net" && Secrets.pushoverNotificationKey != "" else {
            print("\n\n\n❌No Pushover Key\n\n\n")
            return
        }
        print("\n\n\n✅Pushover Key: \(Secrets.pushoverNotificationKey)\n\n\n")
        let url = URL(string: "https://api.pushover.net/1/messages.json?token=\(Secrets.pushoverNotificationKey)&user=um3jmo7mud1b1doesrfhfn93s79gxj&device=Morris_iPhone&title=\(title.pushoverEncoding)&message=\(body.pushoverEncoding)")!

        var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        let jsonDictionary: [String: Any] = [:]
        let data = try! JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
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
        }
        task.resume()
    }
}

extension String {
    var pushoverEncoding: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: " ", with: "+").replacingOccurrences(of: "%20", with: "+") ?? self
    }
}
