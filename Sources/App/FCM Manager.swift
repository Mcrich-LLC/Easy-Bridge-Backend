//
//  FCM Manager.swift
//  
//
//  Created by Morris Richman on 6/21/23.
//

import Foundation
import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import FCM

class FcmManager {
    static let shared = FcmManager()
    private var app: Application?
    
    func configure(_ app: Application) {
        self.app = app
        app.fcm.configuration = .envServiceAccountKey
    }
    
    func send(_ token: String, title: String, body: String, data: FCMApnsApsObject) {
        guard let app else {
            return
        }
        let info = FCMNotification(title: title, body: body)
        var apnsHeaders: [String : String]? {
            guard let mutableContent = data.mutableContent else { return nil }
            return ["mutable_content" : "\(mutableContent)"]
        }
        let message = FCMMessage(token: token, notification: info, apns: FCMApnsConfig(headers: apnsHeaders, aps: data))
        app.fcm.send(message).map { result in
            print(result)
        }
    }
}
