//
//  File.swift
//  
//
//  Created by Leo Dion on 8/8/21.
//

import Foundation

public struct Person : Codable {
  public init(name: String = "") {
    self.name = name
  }
  
  public var name : String
}
