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
        let rootBridges = routes.grouped("")
        rootBridges.get(use: index)
        rootBridges.post(use: create)
        rootBridges.put(use: update)
        let bridges = routes.grouped("bridges")
        bridges.get(use: index)
        bridges.post(use: create)
        bridges.put(use: update)
    }
    func index(req: Request) throws -> EventLoopFuture<[BridgeModel]> {
        throw Abort(.forbidden)
        return BridgeModel.query(on: req.db).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let bridge = try req.content.decode(BridgeModel.self)
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
        return bridge.save(on: req.db).transform(to: .ok)
        } else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
    }
    
    // PUT Request /bridge routes
    func update(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let bridge = try req.content.decode(BridgeModel.self)
        
        
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
        
        return BridgeModel.find(bridge.id, on: req.db)
                .unwrap(or: Abort(.notFound))
                .flatMap {
                    $0.status = bridge.status
                    return $0.update(on: req.db).transform(to: .ok)
                }
        } else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
    }
    
}

