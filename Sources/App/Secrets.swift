import Foundation
import Vapor

// swiftlint:disable superfluous_disable_command line_length

enum Secrets {
    static let internalEditBearerToken = Environment.get("internalEditBearerToken") ?? "internalEditBearerToken"
    static let firebaseCloudMessagingBearerToken = Environment.get("firebaseCloudMessagingBearerToken") ?? "firebaseCloudMessagingBearerToken"
    static let firebaseWebAuthToken = Environment.get("firebaseWebAuthToken") ?? "firebaseWebAuthToken"
    
    static func authorizeToken(token: String?) -> Bool {
        if token == internalEditBearerToken {
            return true
        } else {
            return false
        }
    }
    static let runBindPort = Int(Environment.get("APP_PORT") ?? "8080")
    static let rssBridgePort = Int(Environment.get("RSS_BRIDGE_PORT") ?? "3000")
    static let pushoverNotificationKey = Environment.get("pushoverNotificationKey") ?? "pushoverNotificationKey"
    static let devDeviceFCMId = Environment.get("devDeviceFCMId") ?? "devDeviceFCMId"
}
