//
//  File.swift
//  
//
//  Created by Leo Dion on 7/21/21.
//

import Vapor
import LstsKit

extension LstsItem : Content {}
extension LstsItemRequest : Content {}

enum LstsError : Error {
  case notImplemented
}

public struct LstsItemController {
  public func get (_ request: Request) -> EventLoopFuture<LstsItem> {
    return request.eventLoop.future(error: LstsError.notImplemented)
  }
  
  public func list (_ request: Request) -> EventLoopFuture<[LstsItem]> {
    return request.eventLoop.future(error: LstsError.notImplemented)
  }
  
  public func create (_ request: Request) -> EventLoopFuture<LstsItem> {
    return request.eventLoop.future(error: LstsError.notImplemented)
  }
  
  public func update (_ request: Request) -> EventLoopFuture<LstsItem> {
    return request.eventLoop.future(error: LstsError.notImplemented)
  }
  
  public func delete (_ request: Request) -> EventLoopFuture<HTTPResponseStatus> {
    return request.eventLoop.future(error: LstsError.notImplemented)
  }
}

extension LstsItemController : RouteCollection {
  public func boot(routes: RoutesBuilder) throws {
    routes.delete(["items"], use: self.delete(_:))
    routes.get(["items", ":id"], use: self.get(_:))
    routes.post(["items"], use: self.delete(_:))
    routes.delete(["items", ":id"], use: self.delete(_:))
    routes.put(["items", ":id"], use: self.delete(_:))
  }
  
  
}
