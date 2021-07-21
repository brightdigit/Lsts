//
//  File.swift
//  
//
//  Created by Leo Dion on 7/21/21.
//


import Fluent
import Vapor
import LstsKit

final class LstsItemModel : Model {
  static let schema = "Items"
  
  @ID()
  public var id: UUID?
  
  @Field(key: "title")
  public var title: String
  
  @Field(key: "completedAt")
  public var completedAt: Date?
  
  init() {
    
  }
  init(id: UUID? = nil, title: String, completedAt: Date? = nil) {
    self.id = id
    self.title = title
    self.completedAt = completedAt
  }
}


extension LstsItemModel {
  convenience init(request: LstsItemRequest) {
    self.init(title: request.title, completedAt: request.completedAt)
  }
}
