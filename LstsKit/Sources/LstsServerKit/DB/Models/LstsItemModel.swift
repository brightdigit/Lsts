//
//  File.swift
//  
//
//  Created by Leo Dion on 7/21/21.
//


import Fluent
import Vapor

final class LstsItemModel : Model {
  static let schema = "Items"
  
  @ID()
  public var id: UUID?
  
  @Field(key: "title")
  public var title: String
  
  @Field(key: "completedAt")
  public var completedAt: Date?
}
