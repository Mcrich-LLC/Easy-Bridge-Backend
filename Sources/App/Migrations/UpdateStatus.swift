//
//  Update Status.swift
//  
//
//  Created by Morris Richman on 8/17/22.
//

import Fluent

struct UpdateStatus: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("bridges")
            .id()
            .field("name", .string, .required)
            .field("status", .string, .required)
            .field("maps_url", .string, .required)
            .field("address", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("bridges").delete()
    }
}
