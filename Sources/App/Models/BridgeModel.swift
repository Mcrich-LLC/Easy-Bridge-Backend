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
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    @Field(key: "status")
    var status: String
    @Field(key: "maps_url")
    var maps_url: String
    @Field(key: "address")
    var address: String
    @Field(key: "latitude")
    var latitude: Double
    @Field(key: "longitude")
    var longitude: Double
    
    init() {}
    
    init(id:UUID? = nil, name: String, status: String, maps_url: String, address: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.status = status
        self.maps_url = maps_url
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }
}
