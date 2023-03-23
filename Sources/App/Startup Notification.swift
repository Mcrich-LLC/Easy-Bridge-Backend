//
//  File.swift
//  
//
//  Created by Morris Richman on 3/22/23.
//

import Foundation

class StartupNotification {
    static func push() {
        guard Secrets.pushoverNotificationKey != "get-from-pushover.net" && Secrets.pushoverNotificationKey != "" else {
            return
        }
        let url = URL(string: "https://api.pushover.net/1/messages.json?token=\(Secrets.pushoverNotificationKey)&user=um3jmo7mud1b1doesrfhfn93s79gxj&device=Morris_iPhone&title=Easy+Bridge+Backend&message=Easy+Bridge+Backend+Started+Up")!

        var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        let jsonDictionary: [String: Any] = [:]
        let data = try! JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
        let task = URLSession.shared.uploadTask(with: request, from: data) { (responseData, response, error) in
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
