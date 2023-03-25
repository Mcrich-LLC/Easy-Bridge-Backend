//
//  Secrets-Example.swift
//  
//
//  Created by Morris Richman on 8/19/22.
//

import Foundation

// swiftlint:disable line_length

enum SecretsExample {
    static let twitterbearerToken = "paste-your-twitter-api-key-here-and-replace-this-string--example: aaaaaaapapppppiiiiiiiiiKeeeeeeeeyyyyyyyyy"
    static let internalEditBearerToken = "internal-bearer-token-to-update-database-*you*-come-up-with-this"
    static let firebaseCloudMessagingBearerToken = "internal-bearer-token-to-send-notifications"
    
    static func authorizeToken(token: String?) -> Bool {
        if token == internalEditBearerToken {
            return true
        } else {
            return false
        }
    }
    static let runBindPort = 8081
    static let pushoverNotificationKey = "get-from-pushover.net"
}
