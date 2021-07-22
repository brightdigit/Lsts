//
//  File.swift
//  
//
//  Created by Leo Dion on 7/21/21.
//

import Vapor
import LstsKit
import Fluent

extension LstsItem : Content {
  init (model: LstsItemModel) throws {
    let id = try  model.requireID()
    self.init(id: id, title: model.title, completedAt: model.completedAt)
  }
  
}
extension LstsItemRequest : Content {}

public struct LstsItemController {
  public func get (_ request: Request) -> EventLoopFuture<LstsItem> {
    
    return request.eventLoop.future(error: Abort(.notImplemented))
  }
  
  public func list (_ request: Request) -> EventLoopFuture<[LstsItem]> {
    return LstsItemModel.query(on: request.db).all().flatMapEachThrowing(LstsItem.init(model:))
  }
  
  public func create (_ request: Request) -> EventLoopFuture<LstsItem> {
    let itemRequest : LstsItemRequest
    do {
      itemRequest = try request.content.decode(LstsItemRequest.self)
    } catch  {
      return request.eventLoop.future(error: Abort.init(.badRequest))
    }
    let listItem = LstsItemModel(request: itemRequest)
    
    return listItem.create(on: request.db).transform(to: listItem).flatMapThrowing(LstsItem.init(model:))
  }
  
  public func update (_ request: Request) -> EventLoopFuture<LstsItem> {
    return request.eventLoop.future(error: Abort(.notImplemented))
  }
  
  public func delete (_ request: Request) -> EventLoopFuture<HTTPResponseStatus> {
    let id : UUID
    do {
     id = try request.parameters.require("id", as: UUID.self)
    } catch {
      return request.eventLoop.future(error: Abort.init(.badRequest))
    }
    return LstsItemModel
      .find(id, on: request.db)
      .unwrap(orError: Abort(.notFound))
      .flatMap{ $0.delete(on: request.db) }
      .transform(to: HTTPResponseStatus.noContent)
  }
}

extension LstsItemController : RouteCollection {
  public func boot(routes: RoutesBuilder) throws {
    routes.get(["items"], use: self.list(_:))
    routes.get(["items", ":id"], use: self.get(_:))
    routes.post(["items"], use: self.create(_:))
    routes.delete(["items", ":id"], use: self.delete(_:))
    routes.put(["items", ":id"], use: self.update(_:))
  }
  
  
}
