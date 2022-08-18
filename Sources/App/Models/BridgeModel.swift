//
//  Bridge.swift
//  
//
//  Created by Morris Richman on 8/17/22.
//

import Fluent
import Vapor
import Foundation

final class BridgeModel: Model, Content {
    static let schema = "bridges"
    
    @ID(key: .id)
    var id: String?
    
    @Field(key: "name")
    var name: String
    @Field(key: "status")
    var status: String
    
    init() {}
    
    init(id:String? = nil, name: String, status: String) {
        self.id = id
        self.name = name
        self.status = status
    }
}
