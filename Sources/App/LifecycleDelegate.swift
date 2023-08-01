//
//  LifecycleDelegate.swift
//  
//
//  Created by Morris Richman on 6/23/23.
//

import Vapor

struct LifecycleDelegate: LifecycleHandler {
    func didBoot(_ application: Application) throws {
        if application.environment == .production {
            SystemNotifications.pushStartup()
        } else if application.environment == .testing {
            SystemNotifications.pushBetaStartup()
        }
    }
    
    func shutdown(_ application: Application) {
        if application.environment == .production {
            SystemNotifications.pushShutdown()
        } else if application.environment == .testing {
            SystemNotifications.pushBetaShutdown()
        }
    }
}
