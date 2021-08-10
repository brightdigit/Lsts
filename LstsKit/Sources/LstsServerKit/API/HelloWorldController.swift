//
//  File.swift
//  
//
//  Created by Leo Dion on 8/8/21.
//

import Vapor
import LstsKit

extension Person : Content {}

public struct HelloWorldController : RouteCollection {
  public func boot(routes: RoutesBuilder) throws {
    // curl http://localhost:8080/hello/leo
    routes.get(["hello", ":name"]) { request -> String in
      let name = try request.parameters.require("name")
      return "hello \(name)!"
    }
    // curl -d '{"name" : "leo"}'  -H 'Content-Type: application/json' http://localhost:8080/hello
    routes.post(["hello"]) { request -> String in
      let person = try request.content.decode(Person.self)
      return "hello \(person.name)!"
    }
  }
}
