//
//  LstsApp.swift
//  Lsts
//
//  Created by Leo Dion on 7/21/21.
//

import SwiftUI


@available(iOS 14.0, *)
public protocol LstsApp: App {

}

@available(iOS 14.0, *)
public extension LstsApp {
  var body: some Scene {
      WindowGroup {
        ContentView().environmentObject(LstsObject())
      }
  }
}
