//
//  Status Controller.swift
//  
//
//  Created by Morris Richman on 8/17/22.
//

import Fluent
import Vapor
import Foundation
import VaporCron

struct BridgeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let bridges = routes.grouped("bridges")
        bridges.get(use: index)
        bridges.post(use: create)
        bridges.put(use: update)
    }
    func index(req: Request) throws -> EventLoopFuture<[BridgeModel]> {
        return BridgeModel.query(on: req.db).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let bridge = try req.content.decode(BridgeModel.self)
        if req.headers.bearerAuthorization?.token == "y8r7U6kyvINlswPyxATXScB2wZQpCAuOUf0uWu8PEct0AvnJrQj7HZlmfQ3mhAJvKv3A5qk3Kiu1mtIjnKMiKQJdiyzfda0WUCTD" {
        return bridge.save(on: req.db).transform(to: .ok)
        } else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
    }
    
    // PUT Request /bridge routes
    func update(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let bridge = try req.content.decode(BridgeModel.self)
        if req.headers.bearerAuthorization?.token == "y8r7U6kyvINlswPyxATXScB2wZQpCAuOUf0uWu8PEct0AvnJrQj7HZlmfQ3mhAJvKv3A5qk3Kiu1mtIjnKMiKQJdiyzfda0WUCTD" {
        
        return BridgeModel.find(bridge.id, on: req.db)
                .unwrap(or: Abort(.notFound))
                .flatMap {
                    $0.status = bridge.status
                    $0.maps_url = bridge.maps_url
                    $0.address = bridge.address
                    $0.latitude = bridge.latitude
                    $0.longitude = bridge.longitude
                    return $0.update(on: req.db).transform(to: .ok)
                }
        } else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
    }
    
}

