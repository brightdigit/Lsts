//
//  File.swift
//  
//
//  Created by Leo Dion on 8/8/21.
//

import Vapor

public struct HelloWorldController : RouteCollection {
  public func boot(routes: RoutesBuilder) throws {
    routes.get(["hello", ":name"]) { request -> String in
      let name = try request.parameters.require("name")
      return "hello \(name)!"
    }
  }
}
