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
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("bridges").delete()
    }
}
